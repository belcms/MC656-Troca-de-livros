from datetime import datetime
from sqlalchemy import Boolean, Column, Date, DateTime, ForeignKey, String
from sqlalchemy.orm import relationship
from app.core.database import Base
import uuid

class User(Base):
    __tablename__ = "users"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = Column(String, unique=True, index=True)
    username_normalized = Column(String, unique=True, index=True, nullable=True)
    email = Column(String, unique=True, index=True)
    email_normalized = Column(String, unique=True, index=True, nullable=True)
    full_name = Column(String, index=True)
    cep = Column(String, index=True)
    password_hash = Column(String, nullable=True)
    birth_date = Column(Date, nullable=True)
    google_subject = Column(String, unique=True, index=True, nullable=True)
    onboarding_complete = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    announcements = relationship("TradeAnnouncement", back_populates="user")
    sessions = relationship("AuthSession", back_populates="user", cascade="all, delete-orphan")


class AuthSession(Base):
    __tablename__ = "auth_sessions"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    refresh_token_hash = Column(String(64), unique=True, nullable=False, index=True)
    expires_at = Column(DateTime, nullable=False)
    revoked_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    user = relationship("User", back_populates="sessions")
