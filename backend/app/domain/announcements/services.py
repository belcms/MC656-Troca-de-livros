from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException
from app.domain.announcements import models
from app.domain.announcements.models import Status
from app.api.v1.announcements.schemas import FeedAnnouncementResponse
from app.domain.books.models import Edition, Book

def get_announcement_details(db: Session, id = str):
    announcements = db.query(models.TradeAnnouncement).filter(models.TradeAnnouncement.id == id).first()
    
    if not announcements:
        raise HTTPException(status_code=404, detail="Announcement not found")
    
    edition = announcements.edition
    book = edition.book

    text = {
        "id": announcements.id,
        "user_id": announcements.user_id,
        "edition_id": announcements.edition_id,
        "real_photo_url": announcements.real_photo_url,
        "condition": announcements.condition.value,
        "description": announcements.description,
        "create_date": announcements.create_date.isoformat(),
        "status": announcements.status.value,
        "edition": {
            "id": edition.id,
            "book_id": edition.book_id,
            "publisher": edition.publisher,
            "publish_year": edition.publish_year
        },
        "book": {
            "id": book.id,
            "title": book.title,
            "author": book.author,
            "synopsis": book.synopsis
        }
    }
    
    return text

def get_feed_announcements(db: Session, limit: int = 20, offset: int = 0):
    """
    Retrieves a paginated list of available trade announcements for the feed.

    This function queries the database for announcements with an 'Available' status, 
    ordering them from newest to oldest. It uses eager loading (joinedload) to 
    fetch related Edition, Book, and User data in a single query, preventing N+1 
    performance issues.

    Args:
        db (Session): The active SQLAlchemy database session.
        limit (int, optional): The maximum number of records to return. Defaults to 20.
        offset (int, optional): The number of records to skip for pagination. Defaults to 0.

    Returns:
        list[FeedAnnouncementResponse]: A list of mapped announcement objects 
        containing the necessary data for the feed UI.
    """
    
    announcements = db.query(models.TradeAnnouncement).options(
        joinedload(models.TradeAnnouncement.edition).joinedload(Edition.book),
        joinedload(models.TradeAnnouncement.user)
    ).filter(models.TradeAnnouncement.status == Status.Available).order_by(models.TradeAnnouncement.create_date.desc()).limit(limit).offset(offset).all()


    return [
        FeedAnnouncementResponse(
            id=ann.id,
            title=ann.edition.book.title,
            real_photo_url=ann.real_photo_url,
            publishYear=ann.edition.publish_year,
            cep=ann.user.cep
        )
        for ann in announcements
    ]
    