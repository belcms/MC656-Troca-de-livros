from sqlalchemy.orm import Session
from sqlalchemy import case
from typing import Optional
from . import models
from app.domain.announcements.models import TradeAnnouncement, Status
from app.domain.books.models import Edition, Book
from app.domain.users.models import User

# Função focada APENAS em buscar dados. 
# Ela não sabe o que é uma requisição HTTP ou o que é FastAPI.
def get_users(db: Session, limit: int = 5):
    return db.query(models.User).limit(limit).all()


def get_user_announcements(db: Session, user_id: str, status_filter: Optional[Status] = None):
    """Build My Books cards for all announcements created by a user.

    Query details:
        - Joins ``TradeAnnouncement`` -> ``Edition`` -> ``Book``.
        - Selects only fields needed by My Books cards.
        - Filters by ``TradeAnnouncement.user_id == user_id``.
        - Orders by status priority: Available, Reserved, Traded, fallback.

    The function does not raise when user_id is unknown; it returns an
    empty list whenever no matching announcements are found.

    Args:
        db: Active SQLAlchemy session.
        user_id: User identifier to scope announcements.

    Returns:
        list[dict[str, object]]: Card dictionaries with keys
        ``id``, ``title``, ``publish_year``, ``real_photo_url``, ``status``.
    """
    status_order = case(
        (TradeAnnouncement.status == Status.Available, 1),
        (TradeAnnouncement.status == Status.Reserved, 2),
        (TradeAnnouncement.status == Status.Traded, 3),
        else_=4
    )

    query = (
        db.query(
            TradeAnnouncement.id,
            TradeAnnouncement.real_photo_url,
            TradeAnnouncement.status,
            Book.title,
            Edition.publish_year,
        )
        .join(Edition, TradeAnnouncement.edition_id == Edition.id)
        .join(Book, Edition.book_id == Book.id)
        .filter(TradeAnnouncement.user_id == user_id)
    )

    if status_filter:
        query = query.filter(TradeAnnouncement.status == status_filter)

    results = query.order_by(status_order).all()
    
    cards = []
    for row in results:
        cards.append({
            "id": row.id,
            "title": row.title,
            "publish_year": row.publish_year,
            "real_photo_url": row.real_photo_url,
            "status": row.status,
        })
        
    return cards
