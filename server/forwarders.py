import random
import uuid
from datetime import date, timedelta

from pydantic import BaseModel


class Quote(BaseModel):
    forwarder: str
    mode: str
    price: float
    estimated_arrival: date
    container_type: str
    quote_ref: str


class ForwarderError(Exception):
    pass


class MockForwarder:
    def __init__(self, name: str):
        self.name = name

    def quote(self, mode: str, container_type: str) -> Quote:
        if random.random() < 0.3:
            print(f"{self.name}: failed, no answer")
            raise ForwarderError(f"{self.name} did not answer")
        if mode == "sea":
            price = random.randint(2000, 6000)
            days = random.randint(20, 35)
        else:
            price = random.randint(8000, 20000)
            days = random.randint(3, 7)
        return Quote(
            forwarder=self.name,
            mode=mode,
            price=price,
            estimated_arrival=date.today() + timedelta(days=days),
            container_type=container_type,
            quote_ref=f"{self.name}-{uuid.uuid4().hex[:8]}",
        )


FORWARDERS = [MockForwarder("Forwarder A"), MockForwarder("Forwarder B"), MockForwarder("Forwarder C")]
