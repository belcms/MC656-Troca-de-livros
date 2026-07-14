from sqlalchemy import Column, Float, String
from sqlalchemy.orm import relationship
from app.core.database import Base


class Location(Base):
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