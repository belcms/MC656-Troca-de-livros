from datetime import datetime
from sqlalchemy import Column, Date, DateTime, ForeignKey, String

from sqlalchemy.orm import relationship, synonym
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
    password_hash = Column(String, nullable=True)
    birth_date = Column(Date, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    cep_id = Column(String(8), ForeignKey("locations.cep"), index=True)
    cep = synonym("cep_id")

    announcements = relationship("TradeAnnouncement", back_populates="user")
    location = relationship("Location", back_populates="users")
    wishlist = relationship("Wishlist", back_populates="user", cascade="all, delete-orphan")
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

class Wishlist(Base):
    __tablename__ = "wishlist"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"))
    edition_id = Column(String(36), ForeignKey("editions.id"))

    user = relationship("User", back_populates="wishlist")
    edition = relationship("Edition", back_populates="wishlisted_by")
