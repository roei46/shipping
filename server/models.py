import uuid
from datetime import date, datetime

from sqlalchemy import ForeignKey, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    username: Mapped[str] = mapped_column(unique=True)
    password_hash: Mapped[str]


class Shipment(Base):
    __tablename__ = "shipments"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"))
    status: Mapped[str] = mapped_column(default="preparing_options")
    selected_option_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("options.id"))
    created_at: Mapped[datetime] = mapped_column(server_default=func.now())

    quantity: Mapped[int]
    weight_kg: Mapped[float]
    length_cm: Mapped[float]
    width_cm: Mapped[float]
    height_cm: Mapped[float]
    package_type: Mapped[str]
    delivery_date: Mapped[date]
    shipping_mode: Mapped[str]
    pickup_address: Mapped[str]
    delivery_address: Mapped[str]
    priority: Mapped[str]
    temperature_control: Mapped[bool]
    customs_by: Mapped[str]
    insurance_by: Mapped[str]
    local_trucking_by: Mapped[str]
    incoterms: Mapped[str]


class Option(Base):
    __tablename__ = "options"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    shipment_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("shipments.id"))
    forwarder: Mapped[str]
    mode: Mapped[str]
    price: Mapped[float]
    estimated_arrival: Mapped[date]
    container_type: Mapped[str]
    quote_ref: Mapped[str]    