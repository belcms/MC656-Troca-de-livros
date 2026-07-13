from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db

from app.api.v1.announcements.schemas import MyBooksCardResponse
# Importamos o nosso "cozinheiro"
from app.domain.users import services 
from app.domain.users.models import User
from app.domain.auth.security import get_current_user
from app.domain.auth.schemas import UserResponse

router = APIRouter(
    prefix="/api/v1/users",
    tags=["Users"],
)

@router.get("/")
def get_users(db: Session = Depends(get_db), _: User = Depends(get_current_user)):
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

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id, "full_name": current_user.full_name,
        "nickname": current_user.username, "email": current_user.email,
        "birth_date": current_user.birth_date, "cep": current_user.cep,
    }

@router.get("/me/announcements", response_model=List[MyBooksCardResponse])
def get_my_announcements(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return services.get_user_announcements(db=db, user_id=current_user.id)

@router.get(
        "/{user_id}/announcements", 
        response_model=List[MyBooksCardResponse], 
        summary="Get User Books (Announcements)", 
        description="Retrieves a specialized list of book announcements created by a specific user.")
def get_user_announcements(user_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Return the card list used by the backend My Books flow.

    The endpoint delegates to the users service, which joins announcements,
    editions, and books to build a lightweight card payload.

    Current behavior:
        - Returns HTTP 200 with a list of cards.
        - Returns an empty list when the user has no announcements.
        - Returns HTTP 403 when user_id differs from the authenticated user.

    Args:
        user_id: User identifier from path parameters.
        db: SQLAlchemy session injected by FastAPI.

    Returns:
        List[MyBooksCardResponse]: Ordered cards for the My Books screen.
    """
    if user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Acesso negado")
    announcements = services.get_user_announcements(db=db, user_id=user_id)
    return announcements
