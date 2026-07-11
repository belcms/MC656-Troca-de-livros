import uuid
import enum
from sqlalchemy import Enum as SQLAlchemyEnum, Column, Float, String, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base
from pydantic import BaseModel


class location(Base):
    __tablename__ = "locations"

    cep = Column(String(8), primary_key=True)
    city = Column(String)
    state = Column(String)
    country = Column(String)
    district = Column(String)
    lat = Column(Float)
    long = Column(Float)

    # Relacionamentos reversos
    users = relationship("User", back_populates="location")
    announcements = relationship("TradeAnnouncement", back_populates="location")

#pydantic
class LocationPydantic(BaseModel):
    city: str
    state: str
    country: str
    district: str
    lat: float
    long: float