from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.core.database import get_db

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
    condition: str | None = Query(default=None),
    genre: str | None = Query(default=None),
    db: Session = Depends(get_db),
    publish_year: int | None = Query(default=None),
):
    """Return the feed list used by the main announcements timeline.

    Args:
        limit: Maximum number of announcements to return.
        offset: Number of announcements to skip for pagination.
        condition: Optional filter for the book conservation condition.
        genre: Optional filter for the literary genre.
        db: SQLAlchemy session injected by FastAPI.

    Returns:
        list[FeedAnnouncementResponse]: A filtered list of announcements.
    """
    return get_feed_announcements(
        db,
        limit=limit,
        offset=offset,
        condition=condition,
        genre=genre,
        publish_year=publish_year
    )

@router.post("/{user_id}", status_code=201)
def create_announcement_route(user_id: str, body: announcements_schemas.TradeAnnouncementPydantic, db: Session = Depends(get_db)):
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
    return service_create_announcement(user_id, body, db)

