from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session, Query
from app.core.database import get_db
from app.domain.announcements.services import get_announcement_details
from schemas import FeedAnnouncementResponse
from domain.announcements.services import get_feed_announcements

# router = APIRouter(prefix="/api/v1/books", tags=["books"])

router = APIRouter(prefix="/api/v1/announcements", tags=["announcements"])

@router.get("/details/{id}")
def get_book_details(id: str, db: Session = Depends(get_db)):
    return get_announcement_details(db, id)

@router.get("/feed", response_model=list[FeedAnnouncementResponse])
def feed_announcements(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db)
): return get_feed_announcements(db, limit=limit, offset=offset)