
from pydantic import BaseModel, Field, ConfigDict
from typing import List
from typing import Optional
from app.domain.offer.models import StatusOffer
from datetime import datetime


class OfferedAnnouncementPydantic(BaseModel):
    offered_announcement_id: str = Field(alias="offeredAnnouncementId")
    offer_id: str = Field(alias="offerId")
    
    model_config = ConfigDict(
        from_attributes=True, 
        populate_by_name=True 
    )


class OfferPydantic(BaseModel):
    id: Optional[str]= None
    user_id: str = Field(default=None, alias="userId")
    target_announcement_id: str = Field(default=None, alias="targetAnnouncementId")
    status_offer: StatusOffer = Field(alias="statusOffer")
    created_at: datetime = Field(alias="createdAt")
    
    offered_announcements: List[OfferedAnnouncementPydantic] = Field(alias="offeredAnnouncements")

    model_config = ConfigDict(
        from_attributes=True, 
        populate_by_name=True
    )

class OfferedAnnouncementItem(BaseModel):
    offeredAnnouncementId: str 

class OfferCreate(BaseModel):
    userId: str
    targetAnnouncementId: str
    offeredAnnouncements: List[OfferedAnnouncementItem]


