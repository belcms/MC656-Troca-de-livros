from pydantic import BaseModel, Field 
from typing import Optional
from app.domain.announcements.models import Condition, Status
from datetime import datetime

class TradeAnnouncementPydantic(BaseModel):
    id: Optional[str] = None
    
    user_id: Optional[str] = None 
    
    edition_id: str = Field(alias="editionId") 
    
    condition: Condition
    description: str
    
    real_photo_url: str = Field(alias="coverUrl") 
    
    status: Status = Status.Available
    create_date: Optional[datetime] = None

    class Config:
        from_attributes = True