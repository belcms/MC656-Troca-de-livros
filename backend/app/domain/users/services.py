from sqlalchemy.orm import Session
from sqlalchemy import case
from sqlalchemy.orm import joinedload

from typing import Optional
from . import models
from app.domain.announcements.models import TradeAnnouncement, Status
from app.domain.books.models import Edition

# Função focada APENAS em buscar dados. 
# Ela não sabe o que é uma requisição HTTP ou o que é FastAPI.
def get_users(db: Session, limit: int = 5):
    return db.query(models.User).limit(limit).all()

def get_user_announcements(db: Session, user_id: str, status_filter: Optional[Status] = None):
    """Build My Books cards for all announcements created by a user.
    # ... (docstring mantida) ...
    """
    status_order = case(
        (TradeAnnouncement.status == Status.Available, 1),
        (TradeAnnouncement.status == Status.Reserved, 2),
        (TradeAnnouncement.status == Status.Traded, 3),
        else_=4
    )

    # Mudamos para buscar o objeto inteiro (TradeAnnouncement) com joinedload
    query = (
        db.query(TradeAnnouncement)
        .options(
            joinedload(TradeAnnouncement.edition).joinedload(Edition.book),
            joinedload(TradeAnnouncement.location),
            joinedload(TradeAnnouncement.photos) # <--- Carregamos as fotos aqui!
        )
        .filter(TradeAnnouncement.user_id == user_id)
    )

    if status_filter:
        query = query.filter(TradeAnnouncement.status == status_filter)

    results = query.order_by(status_order).all()
    
    cards = []
    for ann in results:
        # Extração segura de cidade e estado
        city = getattr(ann.location, 'city', None) if ann.location else None
        state = getattr(ann.location, 'state', None) if ann.location else None

        if city and state:
            location = f"{city} - {state}"
        elif city:
            location = city
        elif state:
            location = state
        else:
            location = "Localização não informada"

        # Lógica da Capa (Exatamente igual ao Feed)
        first_photo_url = ""
        if getattr(ann, "photos", None) and len(ann.photos) > 0:
            first_photo_url = ann.photos[0].photo_url
        elif ann.real_photo_url:
            first_photo_url = ann.real_photo_url

        cards.append({
            "id": ann.id,
            "title": ann.edition.book.title,
            "publish_year": ann.edition.publish_year,
            "real_photo_url": ann.real_photo_url,
            "cover_photo": first_photo_url, # <--- Nova chave adicionada!
            "status": ann.status,
            "location": location
        })
        
    return cards