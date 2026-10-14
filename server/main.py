from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import select

from db import SessionLocal
from models import User
from security import verify_password

from datetime import date
from typing import Literal

from pydantic import ConfigDict, Field
from pydantic.alias_generators import to_camel

from models import Shipment

app = FastAPI()

class LoginRequest(BaseModel):
    username: str
    password: str

class Dimensions(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel)

    length_cm: float
    width_cm: float
    height_cm: float


class ShipmentRequest(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel)

    quantity: int = Field(gt=0)
    weight_kg: float = Field(gt=0)
    dimensions: Dimensions
    package_type: Literal["bottles", "cans", "kegs", "pallets"]
    delivery_date: date
    shipping_mode: Literal["sea", "air"]
    pickup_address: str
    delivery_address: str
    priority: Literal["lowestPrice", "fastest"]
    temperature_control: bool
    customs_by: Literal["buyer", "seller"]
    insurance_by: Literal["buyer", "seller"]
    local_trucking_by: Literal["buyer", "seller"]
    incoterms: Literal["EXW", "FCA", "FOB", "CIF", "DAP", "DDP"]

@app.get("/hello")
def hello():
    return {"message": "iron maiden"}

@app.get("/ironMaiden")
def ironMaiden(): return {"roei big fan"}

@app.post("/customer/login")
def login(request: LoginRequest):
    print("login attempt:", request.username)
    with SessionLocal() as session:
        user = session.scalar(select(User).where(User.username == request.username))
    print("user found:", user)

    if user is None or not verify_password(request.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Wrong username or password")

    return {"token": "not-yet"}

@app.post("/customer/shipments", status_code=201)
def create_shipment(request: ShipmentRequest):
    with SessionLocal() as session:
        user = session.scalar(select(User).where(User.username == "roei666"))
        shipment = Shipment(
            user_id=user.id,
            quantity=request.quantity,
            weight_kg=request.weight_kg,
            length_cm=request.dimensions.length_cm,
            width_cm=request.dimensions.width_cm,
            height_cm=request.dimensions.height_cm,
            package_type=request.package_type,
            delivery_date=request.delivery_date,
            shipping_mode=request.shipping_mode,
            pickup_address=request.pickup_address,
            delivery_address=request.delivery_address,
            priority=request.priority,
            temperature_control=request.temperature_control,
            customs_by=request.customs_by,
            insurance_by=request.insurance_by,
            local_trucking_by=request.local_trucking_by,
            incoterms=request.incoterms,
        )
        session.add(shipment)
        session.commit()
        return {"requestId": str(shipment.id), "status": shipment.status}