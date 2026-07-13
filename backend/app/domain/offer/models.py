import uuid
import enum
from sqlalchemy import Enum as SQLAlchemyEnum, Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime
from pydantic import BaseModel


class StatusOffer (str, enum.Enum):
    Pending = "Pending"
    Accepted = "Accepted"
    Rejected = "Rejected"
    Canceled = "Canceled"

class Offer(Base):
    __tablename__ = "offer"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"))
    target_announcement_id = Column(String(36), ForeignKey("trade_announcements.id"))
    status_offer = Column(SQLAlchemyEnum(StatusOffer))
    created_at = Column(DateTime(timezone=True), default=func.now())
    
    offered_announcements = relationship(
        "OfferedAnnouncements", 
        back_populates="offer",
        cascade="all, delete-orphan" 
    )

    user = relationship("User", backref="sent_offers")
    
    target_announcement = relationship(
        "TradeAnnouncement",
        foreign_keys=[target_announcement_id],
        backref="received_offers" 
    )    

class OfferedAnnouncements(Base):
    __tablename__ = "offered_announcements"
    offered_announcement_id = Column(String(36), ForeignKey("trade_announcements.id"), primary_key=True)
    offer_id = Column(String(36), ForeignKey("offer.id"), primary_key=True)

    offer = relationship("Offer", back_populates="offered_announcements")
    announcement = relationship(
        "TradeAnnouncement",
        foreign_keys=[offered_announcement_id],
        backref="involved_in_offers"
    )
