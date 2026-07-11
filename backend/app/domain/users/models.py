from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base
import uuid

class User(Base):
    __tablename__ = "users"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    full_name = Column(String, index=True)
    cep_id = Column(String(8), ForeignKey("locations.cep"))

    announcements = relationship("TradeAnnouncement", back_populates="user")
    location = relationship("location", back_populates="users")