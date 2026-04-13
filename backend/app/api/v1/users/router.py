from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db

from app.api.v1.announcements.schemas import MyBooksCardResponse
# Importamos o nosso "cozinheiro"
from app.domain.users import services 

router = APIRouter(
    prefix="/api/v1/users",
    tags=["Users"],
)

@router.get("/")
def get_users(db: Session = Depends(get_db)):
    # 1. O Router anota o pedido e passa a "panela" (db) para o Service
    users = services.get_users(db=db, limit=5)
    
    # 2. O Router pega a resposta do Service e devolve para o garçom (Flutter)
    return users

@router.get(
        "/{user_id}/announcements", 
        response_model=List[MyBooksCardResponse], 
        summary="Get User Books (Announcements)", 
        description="Retrieves a specialized list of book announcements created by a specific user.")
def get_user_announcements(user_id: str, db: Session = Depends(get_db)):
    """
    Fetch all announcements for a given user.
    
    Args:
        user_id (str): The unique identifier of the user to query.
        db (Session, optional): The database session dependency.
        
    Returns:
        List[MyBooksCardResponse]: A list of book cards formatted for the frontend feed.
    """
    announcements = services.get_user_announcements(db=db, user_id=user_id)
    return announcements
