from sqlalchemy.orm import Session
from fastapi import UploadFile
from app.domain.announcements.models import PhotoTradeAnnouncement
from app.services.storage_service import upload_image_to_supabase


def add_photo_to_announcement(db: Session, announcement_id: str, file: UploadFile):
    try:
        # 1. Manda o arquivo para o Supabase e pega a URL
        photo_url = upload_image_to_supabase(file)
        
        # 2. Cria o registro no banco de dados com a URL recebida
        new_photo = PhotoTradeAnnouncement(
            trade_announcement_id=announcement_id,
            photo_url=photo_url
        )
        
        db.add(new_photo)
        db.commit()
        db.refresh(new_photo)
        
        return new_photo

    except Exception as e:
        db.rollback()
        raise e
    
def remove_photo_from_announcement(db: Session, announcement_id: str, photo_url: str):
    try:
        # 1. Busca a foto exata no banco de dados usando o ID do anúncio e a URL
        photo_record = db.query(PhotoTradeAnnouncement).filter(
            PhotoTradeAnnouncement.trade_announcement_id == announcement_id,
            PhotoTradeAnnouncement.photo_url == photo_url
        ).first()
        
        # 2. Se ela existir, deleta do banco
        if photo_record:
            db.delete(photo_record)
            db.commit()
            return True
            
        return False

    except Exception as e:
        db.rollback()
        raise e