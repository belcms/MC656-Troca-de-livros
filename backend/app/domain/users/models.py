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

    def __init__(self, **kwargs):
        cep = kwargs.pop("cep", None)
        super().__init__(**kwargs)
        if cep is not None and self.cep_id is None:
            self.cep_id = cep

    @property
    def cep(self):
        return self.cep_id

    @cep.setter
    def cep(self, value):
        self.cep_id = value
