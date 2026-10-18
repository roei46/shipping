import uuid

from celery import Celery

from config import settings
from db import SessionLocal
from llm import plan_shipment
from models import Shipment

celery_app = Celery("shipping", broker=settings.redis_url)


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
        shipment.status = "options_ready"
        session.commit()
        # TODO: send the push "Your options are ready" (Firebase).
        # Needs a paid Apple Developer account; until then the app sees the status on refresh.
