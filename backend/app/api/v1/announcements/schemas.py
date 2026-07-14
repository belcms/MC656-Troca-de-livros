from pydantic import BaseModel, ConfigDict, Field
from typing import Optional, List
from datetime import datetime
from app.domain.announcements.models import Condition, Status
from app.domain.announcements.schemas import PhotoResponse

class TradeAnnouncementBase(BaseModel):
    """
    Base schema for a trade announcement.

    This class defines the core attributes required to create or represent
    a trade announcement, excluding database-generated fields.
    """
    edition_id: str
    user_id: str
    real_photo_url: Optional[str] = None
    condition: Condition
    description: Optional[str] = None
    status: Status = Status.Available
    photos: List[PhotoResponse] = []

class TradeAnnouncementResponse(TradeAnnouncementBase):
    """
    Response schema for a trade announcement.

    Extends `TradeAnnouncementBase` by including fields that are generated
    and managed by the system (e.g., database).
    """
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
        location: Location string built from CEP-linked city and state.
    """

    id: str
    title: str
    publish_year: int
    real_photo_url: Optional[str]
    status: Status
    location: str = "Localização não informada"
    cover_photo: str = ""

    model_config = ConfigDict(from_attributes=True)

class FeedAnnouncementResponse(BaseModel):
    """
    Schema representation for the Feed Announcement UI card.

    This view model is tailored to provide only the essential data 
    required to render the list of announcements on the feed screen.

    Attributes:
        id (str): The unique identifier used to fetch the book's detailed information.
        title (str): The title of the book.
        publish_year (int): The publication year of the edition. Serialized as 'publishYear'.
        cep (str): The postal code (CEP) of the user offering the book.
        real_photo_url (Optional[str]): The URL of the actual photo of the book, if available.
    """
    id: str 
    title: str
    publish_year: int = Field(alias='publishYear')
    cep: str
    real_photo_url: Optional[str] = None
    condition: Condition
    cover_photo: str = ""
    distance_km: Optional[float] = Field(default=None, alias="distanceKm")

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
    )


class AnnouncementFilters(BaseModel):
    """Filters supported by the announcements feed."""

    start_year: int | None = Field(
        default=None,
        ge=1000,
        le=2100,
    )

    end_year: int | None = Field(
        default=None,
        ge=1000,
        le=2100,
    )

    conditions: list[str] = Field(
        default_factory=list,
    )

    genres: list[str] = Field(
        default_factory=list,
    )

    max_distance_km: float | None = Field(
        default=None,
        gt=0,
    )
class SearchAnnouncementsResponse(BaseModel):
    """Envelope returned by the announcement search endpoint.

    The frontend needs both the matched cards and the total number of
    matches for pagination and the result counter.
    """

    results: list[FeedAnnouncementResponse]
    total: int

    model_config = ConfigDict(from_attributes=True)

class DeletePhotoRequest(BaseModel):
    photo_url: str