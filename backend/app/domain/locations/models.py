from sqlalchemy import Column, Float, String
from sqlalchemy.orm import relationship
from app.core.database import Base
from pydantic import BaseModel


class Location(Base):
    __tablename__ = "locations"

    cep = Column(String(8), primary_key=True)
    city = Column(String)
    state = Column(String)
    country = Column(String)
    district = Column(String)
    lat = Column(Float)
    long = Column(Float)

    users = relationship(
        "User",
        back_populates="location",
    )

    announcements = relationship(
        "TradeAnnouncement",
        back_populates="location",
    )


class LocationPydantic(BaseModel):
    city: str
    state: str
    country: str
    district: str
    lat: float
    long: float