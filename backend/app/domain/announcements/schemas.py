from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from app.domain.announcements.models import Condition, Status
from datetime import datetime

class TradeAnnouncementPydantic(BaseModel):
    id: Optional[str] = None
    
    user_id: Optional[str] = None 
    
    edition_id: str = Field(alias="editionId")

    cep_id: Optional[str] = Field(default=None, alias="cep")
    
    condition: Condition
    description: str
    
    real_photo_url: str = Field(alias="coverUrl") 
    
    status: Status = Status.Available
    create_date: Optional[datetime] = None

    class Config:
        from_attributes = True



class PhotoResponse(BaseModel):
    id: str
    trade_announcement_id: str
    photo_url: str

    # Configuração para o Pydantic V2 conseguir ler direto do SQLAlchemy
    model_config = ConfigDict(from_attributes=True)
