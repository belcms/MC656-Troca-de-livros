from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field

from app.domain.offer.models import StatusOffer


class OfferedAnnouncementPydantic(BaseModel):
    offered_announcement_id: str = Field(alias="offeredAnnouncementId")
    offer_id: str = Field(alias="offerId")

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
    )


class OfferPydantic(BaseModel):
    id: Optional[str] = None
    user_id: str = Field(alias="userId")
    target_announcement_id: str = Field(alias="targetAnnouncementId")
    status_offer: StatusOffer = Field(alias="statusOffer")
    created_at: datetime = Field(alias="createdAt")
    offered_announcements: List[OfferedAnnouncementPydantic] = Field(
        default_factory=list,
        alias="offeredAnnouncements",
    )

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
    )


class TradeRequestUserResponse(BaseModel):
    id: str
    name: str
    city: str = ""
    state: str = ""
    photo_url: Optional[str] = Field(default=None, alias="photoUrl")

    model_config = ConfigDict(populate_by_name=True)


class TradeRequestBookResponse(BaseModel):
    announcement_id: str = Field(alias="announcementId")
    title: str
    author: str = ""
    publish_year: int = Field(default=0, alias="publishYear")
    city: str = ""
    state: str = ""
    condition: str = ""
    cover_url: Optional[str] = Field(default=None, alias="coverUrl")

    model_config = ConfigDict(populate_by_name=True)


class TradeRequestResponse(BaseModel):
    id: str
    requester: TradeRequestUserResponse
    requested_book: TradeRequestBookResponse = Field(alias="requestedBook")
    offered_books: List[TradeRequestBookResponse] = Field(
        default_factory=list,
        alias="offeredBooks",
    )
    status: StatusOffer
    created_at: datetime = Field(alias="createdAt")

    model_config = ConfigDict(populate_by_name=True)
