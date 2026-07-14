import uuid
import enum
from datetime import datetime
from sqlalchemy import Enum as SQLAlchemyEnum, Column, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base

class Condition(str, enum.Enum):
    """Enum representing the physical condition of the listed book."""

    New = "New"
    Good = "Good"
    Used = "Used"
    Worn = "Worn"

class Status(str, enum.Enum):
    """Enum defining the lifecycle state of a trade announcement."""

    Available = "Available"
    Reserved = "Reserved"
    Traded = "Traded"

class TradeAnnouncement(Base):
    """Domain and persistence entity for book trade announcements.

    Stores who created the announcement, which edition is being offered,
    display metadata (photo/description/condition), and the current trade status.
    """

    __tablename__ = "trade_announcements"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"))
    edition_id = Column(String(36), ForeignKey("editions.id"))
    cep_id = Column(String(8), ForeignKey("locations.cep"))
    real_photo_url = Column(String)
    condition = Column(SQLAlchemyEnum(Condition))
    description = Column(String)
    create_date = Column(DateTime, default=datetime.utcnow)
    status = Column(SQLAlchemyEnum(Status), default=Status.Available)
    
    # ORM relationships for navigation between entities.
    user = relationship("User", back_populates="announcements")
    edition = relationship("Edition", back_populates="announcements")
    location = relationship("Location", back_populates="announcements")
    photos = relationship("PhotoTradeAnnouncement", back_populates="announcement", cascade="all, delete-orphan")



class PhotoTradeAnnouncement(Base):
    __tablename__ = "photo_trade_announcements"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    trade_announcement_id = Column(String(36), ForeignKey("trade_announcements.id"), nullable=False)
    photo_url = Column(String, nullable=False)

    # Cria o vínculo com o anúncio
    announcement = relationship("TradeAnnouncement", back_populates="photos")
