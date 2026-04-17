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
    """Compact card payload for the backend My Books endpoint.

    This schema intentionally exposes only the fields needed by the frontend
    cards and keeps naming aligned with the JSON contract consumed in Flutter.

    Attributes:
        id: Announcement identifier used for future detail/edit actions.
        title: Book title associated with the announcement edition.
        publish_year: Publication year from the selected edition.
        real_photo_url: Optional URL of the real book photo uploaded by user.
        status: Current trade lifecycle state.
    """

    id: str
    title: str
    publish_year: int
    real_photo_url: Optional[str]
    status: Status

    model_config = ConfigDict(from_attributes=True)
