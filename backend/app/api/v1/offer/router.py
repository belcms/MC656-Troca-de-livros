from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db

from app.domain.users.services import get_user_announcements
# Importando o Enum de status da sua modelagem
from app.domain.announcements.models import Status 
# Importando o schema Pydantic que formata a saída (adapte para o nome real do seu schema)
from app.api.v1.announcements.schemas import MyBooksCardResponse

router_offer = APIRouter(prefix="/api/v1/offers", tags=["Offers"])

router_offer_announcement = APIRouter(prefix="/api/v1/offered-announcements", tags=["Offered Announcements"])

@router_offer.get("/eligible-items", response_model=List[MyBooksCardResponse])
def get_eligible_items_for_offer(
    user_id: str, 
    db: Session = Depends(get_db)
):
    """
    Retorna a lista de anúncios do usuário logado que estão com status 'Available',
    prontos para serem selecionados em uma nova proposta de troca.
    """
   
    eligible_books = get_user_announcements(
        db=db, 
        user_id=user_id, 
        status_filter=Status.Available
    )
    
    
    return eligible_books