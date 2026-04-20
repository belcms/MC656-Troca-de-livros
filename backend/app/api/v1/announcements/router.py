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
    # O teste vai interceptar essa chamada
    return get_announcement_details(db, id)

@router.get("/feed", response_model=list[FeedAnnouncementResponse])
def feed_announcements_route(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    # O teste vai interceptar essa chamada
    return get_feed_announcements(db, limit=limit, offset=offset)

@router.post("/{user_id}", status_code=201)
def create_announcement_route(user_id: str, body: announcements_schemas.TradeAnnouncementPydantic, db: Session = Depends(get_db)):
    # Aqui usamos o apelido, assim a rota não chama a si mesma!
    return service_create_announcement(user_id, body, db)