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

    start_year: int | None = Query(
        default=None,
        ge=1000,
        le=2100,
    ),
    end_year: int | None = Query(
        default=None,
        ge=1000,
        le=2100,
    ),

    condition: list[str] | None = Query(
        default=None,
    ),
    genre: list[str] | None = Query(
        default=None,
    ),

    max_distance_km: float | None = Query(
        default=None,
        gt=0,
    ),


    db: Session = Depends(get_db),
):
    """Return the filtered announcements feed.

    Args:
        limit: Maximum number of announcements returned.
        offset: Number of announcements skipped.
        start_year: Minimum publication year.
        end_year: Maximum publication year.
        condition: One or more conservation conditions.
        genre: One or more literary genres.
        db: SQLAlchemy session injected by FastAPI.

    Returns:
        A filtered list of feed announcements.
    """
    return get_feed_announcements(
        db=db,
        limit=limit,
        offset=offset,
        start_year=start_year,
        end_year=end_year,
        conditions=condition,
        genres=genre,
        max_distance_km=max_distance_km,

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

