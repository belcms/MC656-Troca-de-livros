from sqlalchemy.orm import Session
from sqlalchemy import case
from . import models
from app.domain.locations.models import location as LocationModel
import app.domain.locations.services as locations_services
from app.domain.announcements.models import TradeAnnouncement, Status
from app.domain.books.models import Edition, Book
from app.domain.users.models import User

# Função focada APENAS em buscar dados. 
# Ela não sabe o que é uma requisição HTTP ou o que é FastAPI.
def get_users(db: Session, limit: int = 5):
    return db.query(models.User).limit(limit).all()


def get_user_announcements(db: Session, user_id: str):
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

    results = (
        db.query(
            TradeAnnouncement.id,
            TradeAnnouncement.cep_id,
            TradeAnnouncement.real_photo_url,
            TradeAnnouncement.status,
            Book.title,
            Edition.publish_year,
            LocationModel.city, # Novo
            LocationModel.state # Novo
        )
        .join(Edition, TradeAnnouncement.edition_id == Edition.id)
        .join(Book, Edition.book_id == Book.id)
        .outerjoin(LocationModel, TradeAnnouncement.cep_id == LocationModel.cep)
        .filter(TradeAnnouncement.user_id == user_id)
        .order_by(status_order)
        .all()
    )
    
    cards = []
    # Helper: ensure location exists in DB for a cep; if absent, fetch and persist synchronously
    def _ensure_location_for_cep(cep_value: str):
        if not cep_value:
            return None
        try:
            return locations_services.get_or_create_location_by_cep(cep_value, db)
        except Exception:
            return None
    for row in results:
        city = getattr(row, 'city', None)
        state = getattr(row, 'state', None)

        # If location fields are missing but cep_id exists, try to ensure location is persisted
        if (not city or not state) and getattr(row, 'cep_id', None):
            loc = _ensure_location_for_cep(getattr(row, 'cep_id'))
            if loc:
                city = loc.city
                state = loc.state

        if city and state:
            location = f"{city} - {state}"
        elif city:
            location = city
        elif state:
            location = state
        else:
            location = "Localização não informada"

        cards.append({
            "id": row.id,
            "title": row.title,
            "publish_year": row.publish_year,
            "real_photo_url": row.real_photo_url,
            "status": row.status,
            "location": location
        })
        
    return cards
