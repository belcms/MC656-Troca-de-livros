from sqlalchemy.orm import Session
from sqlalchemy import case
from . import models
from app.domain.announcements.models import TradeAnnouncement, Status
from app.domain.books.models import Edition, Book
from app.domain.users.models import User

# Função focada APENAS em buscar dados. 
# Ela não sabe o que é uma requisição HTTP ou o que é FastAPI.
def get_users(db: Session, limit: int = 5):
    return db.query(models.User).limit(limit).all()

def get_user_announcements(db: Session, user_id: str):
    """
    Fetch all announcements associated with a specific user.
    
    This function performs an INNER JOIN across TradeAnnouncement, 
    Edition, and Book tables. It extracts specialized data targeted 
    for the 'My Books' frontend card
    
    Args:
        db (Session): The active SQLAlchemy database session.
        user_id (str): The unique identifier for the user.
        
    Returns:
        List[dict]: A list of dictionaries representing the assembled 
                    cards (id, title, publish_year, real_photo_url, status).
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
            TradeAnnouncement.real_photo_url,
            TradeAnnouncement.status,
            Book.title,
            Edition.publish_year,
        )
        .join(Edition, TradeAnnouncement.edition_id == Edition.id)
        .join(Book, Edition.book_id == Book.id)
        .filter(TradeAnnouncement.user_id == user_id)
        .order_by(status_order)
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
