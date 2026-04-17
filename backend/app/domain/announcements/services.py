from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException
from app.domain.announcements import models
from app.api.v1.announcements.schemas import FeedAnnouncementResponse
from app.domain.books.models import Edition, Book
from app.domain.users.models import User

def get_announcement_details(db: Session, id: str):
    """
    Retrieve complete details of a trade announcement by its ID.

    This function queries the database for a specific `TradeAnnouncement`
    and loads its related entities:
    - User
    - Book edition
    - Book

    If any of these entities are missing, an HTTP 404 exception is raised.

    Args:
        db (Session):
            An active SQLAlchemy database session used to perform queries
            and access persisted data.

        id (str):
            The unique identifier of the trade announcement to retrieve.

    Returns:
        dict:
            A dictionary containing all relevant announcement data,
            structured for easy consumption (e.g., by a REST API or frontend).
            Includes:

            - Announcement data:
                id, user_id, edition_id, description, condition, status,
                creation date, real photo URL

            - User data:
                user_name, user_cep

            - Edition data:
                id, book_id, publisher, publish_year

            - Book data:
                id, title, author, synopsis

    Raises:
        HTTPException (404):
            - If the announcement is not found
            - If the associated edition is missing
            - If the associated book is missing
            - If the associated user is missing
    """

    announcements = db.query(models.TradeAnnouncement).filter(models.TradeAnnouncement.id == id).first()
    
    if not announcements:
        raise HTTPException(status_code=404, detail="Announcement not found")
    
    edition = announcements.edition

    if not edition:
        raise HTTPException(status_code=404, detail="Edition information is missing for this announcement")
    
    book = edition.book

    if not book:
        raise HTTPException(status_code=404, detail="Book information is missing for this edition")
    
    user = announcements.user

    if not user:
         raise HTTPException(status_code=404, detail="User information is missing")
    

    text = {
        "id": announcements.id,
        "user_id": announcements.user_id,
        "user_name": user.username,
        "user_cep": user.cep,
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
    announcements = db.query(models.TradeAnnouncement).options(
        joinedload(models.TradeAnnouncement.edition).joinedload(Edition.book),
        joinedload(models.TradeAnnouncement.user)
    ).limit(limit).offset(offset).all()


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
    