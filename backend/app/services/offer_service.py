
from sqlalchemy.orm import Session
from app.domain.announcements.models import TradeAnnouncement
from app.api.v1.announcements.schemas import MyBooksCardResponse
from app.domain.offer.schemas import OfferCreate
from app.domain.offer.models import Offer, OfferedAnnouncements 


def create_new_offer(db: Session, offer_data: OfferCreate):
    try:
        # 1. Cria a oferta principal (A "capa" da proposta)
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