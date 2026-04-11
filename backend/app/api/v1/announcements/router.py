from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.domain.announcements.services import get_announcement_details

router = APIRouter(prefix="/api/v1/books", tags=["books"])

@router.get("/details/{id}")
def get_book_details(id: str, db: Session = Depends(get_db)):
    return get_announcement_details(db, id)