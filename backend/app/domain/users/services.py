from sqlalchemy.orm import Session
from . import models
from app.domain.announcements.models import TradeAnnouncement
from app.domain.books.models import Edition, Book
from app.domain.users.models import User

# Função focada APENAS em buscar dados. 
# Ela não sabe o que é uma requisição HTTP ou o que é FastAPI.
def get_users(db: Session, limit: int = 5):
    return db.query(models.User).limit(limit).all()

def get_user_announcements(db: Session, user_id: str):
    results = (
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
        .all()
    )
    
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
