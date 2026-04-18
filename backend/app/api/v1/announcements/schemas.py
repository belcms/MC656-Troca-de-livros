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

    model_config = ConfigDict(from_attributes=True)
