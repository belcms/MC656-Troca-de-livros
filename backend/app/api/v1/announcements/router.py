from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.domain.announcements.services import get_announcement_details
from app.api.v1.announcements.schemas import FeedAnnouncementResponse
from app.domain.announcements.services import get_feed_announcements

# router = APIRouter(prefix="/api/v1/books", tags=["books"])

router = APIRouter(prefix="/api/v1/announcements", tags=["announcements"])

@router.get("/details/{id}")
def get_book_details(id: str, db: Session = Depends(get_db)):
    """
    Endpoint to retrieve detailed information about a specific trade announcement.

    This route receives an announcement ID as a path parameter and returns
    its complete details by delegating the logic to `get_announcement_details`.

    Args:
        id (str):
            The unique identifier of the trade announcement.

        db (Session, optional):
            Database session automatically injected via dependency injection
            using FastAPI's `Depends(get_db)`.

    Returns:
        dict:
            A dictionary containing the full details of the requested
            trade announcement, including user, edition, and book data.

    Raises:
        HTTPException (404):
            If the announcement or any related entity is not found.
    """
    return get_announcement_details(db, id)

@router.get("/feed", response_model=list[FeedAnnouncementResponse])
def feed_announcements(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
): return get_feed_announcements(db, limit=limit, offset=offset)