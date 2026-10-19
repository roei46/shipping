import uuid

from celery import Celery
from tenacity import retry, retry_if_exception_type, stop_after_attempt, wait_fixed

from config import settings
from db import SessionLocal
from forwarders import FORWARDERS, ForwarderError
from llm import plan_shipment
from models import Option, Shipment

celery_app = Celery("shipping", broker=settings.redis_url)


@retry(
    retry=retry_if_exception_type(ForwarderError),
    stop=stop_after_attempt(3),
    wait=wait_fixed(1),
    reraise=True,
)
def get_quote(forwarder, mode, container_type):
    return forwarder.quote(mode, container_type)


@celery_app.task
def prepare_options(shipment_id: str):
    with SessionLocal() as session:
        shipment = session.get(Shipment, uuid.UUID(shipment_id))
        details = (
            f"{shipment.quantity} {shipment.package_type}, {shipment.weight_kg} kg, "
            f"{shipment.length_cm}x{shipment.width_cm}x{shipment.height_cm} cm, "
            f"from {shipment.pickup_address} to {shipment.delivery_address}, "
            f"deliver by {shipment.delivery_date}, priority: {shipment.priority}, "
            f"temperature control: {shipment.temperature_control}, "
            f"preferred mode: {shipment.shipping_mode}"
        )
        plan = plan_shipment(details)
        print("plan:", plan)

        quotes = []
        for mode in plan.modes_to_quote:
            container_type = "uld" if mode == "air" else plan.container_type
            for forwarder in FORWARDERS:
                try:
                    quotes.append(get_quote(forwarder, mode, container_type))
                except ForwarderError:
                    print(f"{forwarder.name}: skipped after 3 tries")

        if not quotes:
            print("no quotes at all, shipment stays preparing_options")
            return

        cheapest = min(quotes, key=lambda q: q.price)
        fastest = min(quotes, key=lambda q: q.estimated_arrival)
        chosen = [cheapest] if cheapest == fastest else [cheapest, fastest]

        for q in chosen:
            session.add(Option(
                shipment_id=shipment.id,
                forwarder=q.forwarder,
                mode=q.mode,
                price=q.price,
                estimated_arrival=q.estimated_arrival,
                container_type=q.container_type,
                quote_ref=q.quote_ref,
            ))

        shipment.status = "options_ready"
        session.commit()
        # TODO: send the push "Your options are ready" (Firebase).
        # Needs a paid Apple Developer account; until then the app sees the status on refresh.
