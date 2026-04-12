from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db

from app.api.v1.announcements.schemas import MyBooksCardResponse
# Importamos o nosso "cozinheiro"
from app.domain.users import services 

router = APIRouter(
    prefix="/users",
    tags=["Users"],
)

@router.get("/")
def get_users(db: Session = Depends(get_db)):
    # 1. O Router anota o pedido e passa a "panela" (db) para o Service
    users = services.get_users(db=db, limit=5)
    
    # 2. O Router pega a resposta do Service e devolve para o garçom (Flutter)
    return users

@router.get("/{user_id}/announcements", response_model=List[MyBooksCardResponse])
def get_user_announcements(user_id: str, db: Session = Depends(get_db)):
    announcements = services.get_user_announcements(db=db, user_id=user_id)
    return announcements
