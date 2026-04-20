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
    """Retrieve a list of users.

    The endpoint delegates to the users service to fetch a limited 
    number of users (currently hardcoded to a limit of 5) from the database.

    Args:
        db: SQLAlchemy session injected by FastAPI.

    Returns:
        A list of user payloads to be consumed by the client (e.g., Flutter frontend).
    """
    
    # O Router anota o pedido e passa a "panela" (db) para o Service
    users = services.get_users(db=db, limit=5)
    
    # O Router pega a resposta do Service e devolve para o garçom (Flutter)
    return users

@router.get(
        "/{user_id}/announcements", 
        response_model=List[MyBooksCardResponse], 
        summary="Get User Books (Announcements)", 
        description="Retrieves a specialized list of book announcements created by a specific user.")
def get_user_announcements(user_id: str, db: Session = Depends(get_db)):
    """Return the card list used by the backend My Books flow.

    The endpoint delegates to the users service, which joins announcements,
    editions, and books to build a lightweight card payload.

    Current behavior:
        - Returns HTTP 200 with a list of cards.
        - Returns an empty list when the user has no announcements.
        - Returns an empty list when user_id does not exist.

    Args:
        user_id: User identifier from path parameters.
        db: SQLAlchemy session injected by FastAPI.

    Returns:
        List[MyBooksCardResponse]: Ordered cards for the My Books screen.
    """
    announcements = services.get_user_announcements(db=db, user_id=user_id)
    return announcements
