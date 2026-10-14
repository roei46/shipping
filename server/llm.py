from typing import Literal

import anthropic
from pydantic import BaseModel

from config import settings

MODEL = "claude-haiku-5-5"

client = anthropic.Anthropic(api_key=settings.anthropic_api_key)

PROMPT = """You plan international beer shipments for Corona (Mexico).
Given a shipment request, decide:
- modes_to_quote: which modes are worth getting quotes for (sea, air, or both),
  based on the delivery date, weight and the customer's priority.
- consolidation: FCL (full container) or LCL (shared container) for sea; null if air only.
- container_type: 20ft, 40ft, 40ft_reefer (if temperature control is needed), or uld (air).
- reason: one short sentence.
Never give prices or dates."""


class ShippingPlan(BaseModel):
    modes_to_quote: list[Literal["sea", "air"]]
    consolidation: Literal["FCL", "LCL"] | None
    container_type: Literal["20ft", "40ft", "40ft_reefer", "uld"]
    reason: str


def plan_shipment(shipment_details: str) -> ShippingPlan:
    response = client.messages.parse(
        model=MODEL,
        max_tokens=4096,
        system=PROMPT,
        messages=[{"role": "user", "content": shipment_details}],
        output_format=ShippingPlan,
    )
    return response.parsed_output
