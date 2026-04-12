from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException
from app.domain.announcements import models
from app.api.v1.announcements.schemas import FeedAnnouncementResponse

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
    announcements = db.query(models.TradeAnnouncement).options(
        joinedload(models.TradeAnnouncement.edition).joinedload(models.Edition.book),
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
    