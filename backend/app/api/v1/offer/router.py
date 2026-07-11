from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db

from app.domain.users.services import get_user_announcements
# Importando o Enum de status da sua modelagem
from app.domain.announcements.models import Status 
# Importando o schema Pydantic que formata a saída (adapte para o nome real do seu schema)
from app.api.v1.announcements.schemas import MyBooksCardResponse
from app.services import offer_service as offer_services
from app.domain.offer.schemas import OfferCreate

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

@router_offer.post("/create-offer", status_code=status.HTTP_201_CREATED)
def create_offer_endpoint(
    offer_in: OfferCreate, 
    db: Session = Depends(get_db)
):
    """
    Cria uma nova proposta de troca, vinculando o livro desejado
    aos livros que o usuário está oferecendo.
    """
    try:
        created_offer = offer_services.create_new_offer(db=db, offer_data=offer_in)
        
        return {
            "message": "Proposta enviada com sucesso!",
            "offer_id": created_offer.id
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail=f"Erro ao processar a proposta: {str(e)}"
        )