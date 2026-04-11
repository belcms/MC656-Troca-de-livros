import uuid
import enum
from datetime import datetime
from sqlalchemy import Enum as SQLAlchemyEnum, Column, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base

class Condition(str, enum.Enum):
    New = "New"
    Good = "Good"
    Used = "Used"
    Worn = "Worn"

class Status(str, enum.Enum):
    Available = "Available"
    Reserved = "Reserved"
    Traded = "Traded"

class TradeAnnouncement(Base):
    __tablename__ = "trade_announcements"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"))
    edition_id = Column(String(36), ForeignKey("editions.id"))
    real_photo_url = Column(String)
    condition = Column(SQLAlchemyEnum(Condition))
    description = Column(String)
    create_date = Column(DateTime, default=datetime.utcnow)
    status = Column(SQLAlchemyEnum(Status), default=Status.Available)
    
    # Relationships
    user = relationship("User", back_populates="announcements")
    edition = relationship("Edition", back_populates="announcements")
