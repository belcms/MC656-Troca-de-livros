
from sqlalchemy.orm import Session
from app.domain.announcements.models import TradeAnnouncement
from app.api.v1.announcements.schemas import MyBooksCardResponse
from app.domain.offer.schemas import OfferCreate
from app.domain.offer.models import Offer, OfferedAnnouncements 


def create_new_offer(db: Session, offer_data: OfferCreate):
    try:
        
        if has_pending_offer(db, offer_data.userId, offer_data.targetAnnouncementId):
            raise ValueError("Você já enviou uma proposta para este anúncio. Aguarde a resposta do dono.")

        new_offer = Offer(
            user_id=offer_data.userId,
            target_announcement_id=offer_data.targetAnnouncementId,
            status_offer="Pending" 
        )
        db.add(new_offer)
        db.flush() 
        
        for item in offer_data.offeredAnnouncements:
            offer_item = OfferedAnnouncements(
                offer_id=new_offer.id,
                offered_announcement_id=item.offeredAnnouncementId
            )
            db.add(offer_item)

        
        db.commit()
        db.refresh(new_offer)
        
        return new_offer

    except Exception as e:
        db.rollback() 
        raise e
    
def has_pending_offer(db: Session, user_id: str, target_announcement_id: str) -> bool:
    """Verifica se já existe uma oferta pendente entre usuário e anúncio."""
    existing_offer = db.query(Offer).filter(
        Offer.user_id == user_id,
        Offer.target_announcement_id == target_announcement_id,
        Offer.status_offer == "Pending" 
    ).first()
    
    return existing_offer is not None