import uuid
from datetime import date
from typing import Annotated, Literal

import jwt
from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, ConfigDict, Field, field_validator
from pydantic.alias_generators import to_camel
from sqlalchemy import select
from sqlalchemy.orm import Session

from config import settings
from db import get_db
from models import Option, Shipment, User
from security import create_token, verify_password
from sentry_setup import init_sentry
from worker import prepare_options

init_sentry()

app = FastAPI()
bearer = HTTPBearer(auto_error=False)


@app.exception_handler(RequestValidationError)
def validation_error(request: Request, exc: RequestValidationError):
    errors = [
        {"field": e["loc"][-1], "message": e["msg"].removeprefix("Value error, ")}
        for e in exc.errors()
    ]
    return JSONResponse(status_code=422, content={"errors": errors})


DB = Annotated[Session, Depends(get_db)]

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

    @field_validator("delivery_date")
    @classmethod
    def must_be_future(cls, value: date) -> date:
        if value <= date.today():
            raise ValueError("Must be a future date")
        return value

class ApproveRequest(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel)

    option_id: uuid.UUID


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
    session: DB,
) -> User:
    if credentials is None:
        raise HTTPException(status_code=401, detail="Missing token")
    try:
        payload = jwt.decode(credentials.credentials, settings.jwt_secret, algorithms=["HS256"])
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    user = session.get(User, uuid.UUID(payload["sub"]))
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]


@app.post("/customer/login")
def login(request: LoginRequest, session: DB):
    user = session.scalar(select(User).where(User.username == request.username))

    if user is None or not verify_password(request.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Wrong username or password")

    return {"token": create_token(str(user.id))}

@app.post("/customer/shipments", status_code=201)
def create_shipment(request: ShipmentRequest, user: CurrentUser, session: DB):
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
    prepare_options.delay(str(shipment.id))
    return {"requestId": str(shipment.id), "status": shipment.status}

@app.get("/customer/shipments")
def list_shipments(user: CurrentUser, session: DB):
    shipments = session.scalars(
        select(Shipment).where(Shipment.user_id == user.id).order_by(Shipment.created_at.desc())
    ).all()
    return {"shipments": [{"requestId": str(s.id), "status": s.status} for s in shipments]}   

@app.get("/customer/shipments/{shipment_id}")
def get_shipment(shipment_id: uuid.UUID, user: CurrentUser, session: DB):
    shipment = session.get(Shipment, shipment_id)
    if shipment is None or shipment.user_id != user.id:
        raise HTTPException(status_code=404, detail="Shipment not found")

    options = session.scalars(select(Option).where(Option.shipment_id == shipment.id)).all()
    return {
        "requestId": str(shipment.id),
        "status": shipment.status,
        "options": [
            {
                "optionId": str(o.id),
                "mode": o.mode,
                "price": o.price,
                "estimatedArrival": o.estimated_arrival.isoformat(),
                "containerType": o.container_type,
            }
            for o in options
        ],
    }


@app.post("/customer/shipments/{id}/approve")
def approve(id: uuid.UUID, request: ApproveRequest, user: CurrentUser, session: DB):
    shipment = session.get(Shipment, id)
    if shipment is None or shipment.user_id != user.id:
        raise HTTPException(status_code=404, detail="Shipment not found")
    if shipment.status != "options_ready":
        raise HTTPException(status_code=409, detail="Shipment is not waiting for approval")

    option = session.get(Option, request.option_id)
    if option is None or option.shipment_id != shipment.id:
        raise HTTPException(status_code=404, detail="Option not found")

    shipment.selected_option_id = option.id
    shipment.status = "approved"
    session.commit()
    return {"requestId": str(shipment.id), "status": shipment.status}
