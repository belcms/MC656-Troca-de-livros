from pydantic import BaseModel, Field 
from typing import Optional
from app.domain.announcements.models import Condition, Status
from datetime import datetime

class LocationPydantic(BaseModel):
    cep: str
    
    city: str
    state: str
    country: str
    district: Optional[str] = None
    lat: float
    long: float

    class Config:
        from_attributes = True


class SortPostsByDistanceRequest(BaseModel):
    reference: LocationPydantic
    posts: list[LocationPydantic]
