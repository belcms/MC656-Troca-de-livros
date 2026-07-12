from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.domain.auth.security import get_current_user
from app.domain.users.models import User

from app.api.v1.announcements.schemas import FeedAnnouncementResponse
import app.domain.announcements.schemas as announcements_schemas

from app.domain.announcements.services import (
    get_announcement_details,
    get_feed_announcements,
    create_announcement as service_create_announcement
)

router = APIRouter(prefix="/api/v1/announcements", tags=["announcements"])

@router.get("/details/{id}")
def get_book_details_route(id: str, db: Session = Depends(get_db)):
    """Retrieve details of a specific announcement by its ID.

        The endpoint delegates to the announcements service to fetch the full 
        details of a single announcement.

        Args:
            id: Announcement identifier from path parameters.
            db: SQLAlchemy session injected by FastAPI.

        Returns:
            The detailed announcement payload.
    """
    return get_announcement_details(db, id)

@router.get("/feed", response_model=list[FeedAnnouncementResponse])
def feed_announcements_route(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """Return the feed list used by the main announcements timeline.

    The endpoint delegates to the announcements service to retrieve a paginated
    list of announcements for the general feed.

    Args:
        limit: Maximum number of announcements to return. Constrained between 1 and 100.
        offset: Number of announcements to skip for pagination.
        db: SQLAlchemy session injected by FastAPI.

    Returns:
        list[FeedAnnouncementResponse]: A list of announcements for the feed.
    """
    return get_feed_announcements(db, limit=limit, offset=offset)

@router.post("", status_code=201)
def create_announcement_route(body: announcements_schemas.TradeAnnouncementPydantic, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Create a new trade announcement for a specific user.

    The endpoint delegates to the announcements service to persist a new
    announcement associated with the given user ID.

    Args:
        user_id: User identifier from path parameters.
        body: The payload containing the trade announcement details.
        db: SQLAlchemy session injected by FastAPI.

    Returns:
        The created announcement payload with HTTP 201 status.
    """
    return service_create_announcement(current_user.id, body, db)
