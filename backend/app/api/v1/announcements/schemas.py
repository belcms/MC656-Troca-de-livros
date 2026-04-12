from pydantic import BaseModel, ConfigDict, Field
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
    """
    Schema representation for the 'My Books' UI card.
    
    This view model is personalized to provide only the data needed to render 
    the list of announcements on the user profile screen
    """
    id: str                      # Identifier to open or edit the book
    title: str                  
    publish_year: int            
    real_photo_url: Optional[str] 
    status: Status              

    model_config = ConfigDict(from_attributes=True)

class FeedAnnouncementResponse(BaseModel):
    """"
    Schema representation for the Feed Announcement UI card.
    This view model is personalized to provide only the data needed to render the list of announcements on the feed screen
    """
    id: str #identifier to open the informations of the book
    title: str
    publish_year: int = Field(alias='publishYear')
    cep: str
    real_photo_url: Optional[str]

    model_config = ConfigDict(from_attributes=True)
