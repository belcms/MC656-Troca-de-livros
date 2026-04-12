from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime
from app.domain.announcements.models import Condition, Status

class TradeAnnouncementBase(BaseModel):
    edition_id: str
    real_photo_url: Optional[str] = None
    condition: Condition
    description: Optional[str] = None
    status: Status = Status.Available

class TradeAnnouncementResponse(TradeAnnouncementBase):
    id: str
    user_id: str
    create_date: datetime

    model_config = ConfigDict(from_attributes=True)

class MyBooksCardResponse(BaseModel):
    id: str                      # Needed so the app knows which book to open/edit when clicked
    title: str                   # Comes from Book
    publish_year: int            # Comes from Edition
    real_photo_url: Optional[str]
    status: Status

    model_config = ConfigDict(from_attributes=True)
