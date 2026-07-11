from typing import List

from fastapi import HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.domain.announcements.models import Status, TradeAnnouncement
from app.domain.books.models import Edition
from app.domain.offer.models import OfferedAnnouncements
from app.domain.offer.models import Offer, StatusOffer
from app.domain.offer.schemas import (
    TradeRequestBookResponse,
    TradeRequestResponse,
    TradeRequestUserResponse,
)


def list_received_offers(
    db: Session,
    owner_user_id: str,
) -> List[TradeRequestResponse]:
    offers = (
        db.query(Offer)
        .join(
            TradeAnnouncement,
            Offer.target_announcement_id == TradeAnnouncement.id,
        )
        .filter(TradeAnnouncement.user_id == owner_user_id)
        .options(
            joinedload(Offer.user),
            joinedload(Offer.target_announcement)
            .joinedload(TradeAnnouncement.edition)
            .joinedload(Edition.book),
            joinedload(Offer.target_announcement)
            .joinedload(TradeAnnouncement.user),
            joinedload(Offer.offered_announcements)
            .joinedload(OfferedAnnouncements.announcement)
            .joinedload(TradeAnnouncement.edition)
            .joinedload(Edition.book),
            joinedload(Offer.offered_announcements)
            .joinedload(OfferedAnnouncements.announcement)
            .joinedload(TradeAnnouncement.user),
        )
        .order_by(Offer.created_at.desc())
        .all()
    )

    return [_offer_to_response(offer) for offer in offers]


def get_received_offer(
    db: Session,
    offer_id: str,
    owner_user_id: str,
) -> TradeRequestResponse:
    offer = _find_offer_for_owner(
        db=db,
        offer_id=offer_id,
        owner_user_id=owner_user_id,
    )
    return _offer_to_response(offer)


def accept_offer(
    db: Session,
    offer_id: str,
    owner_user_id: str,
) -> TradeRequestResponse:
    offer = _find_offer_for_owner(
        db=db,
        offer_id=offer_id,
        owner_user_id=owner_user_id,
        lock=True,
    )

    _ensure_pending(offer)

    target = offer.target_announcement
    offered_announcements = [
        relation.announcement
        for relation in offer.offered_announcements
    ]

    _ensure_announcements_available(
        [target, *offered_announcements],
    )

    try:
        offer.status_offer = StatusOffer.Accepted
        target.status = Status.Reserved

        for announcement in offered_announcements:
            announcement.status = Status.Reserved

        competing_offers = (
            db.query(Offer)
            .filter(
                Offer.target_announcement_id == target.id,
                Offer.id != offer.id,
                Offer.status_offer == StatusOffer.Pending,
            )
            .all()
        )

        for competing_offer in competing_offers:
            competing_offer.status_offer = StatusOffer.Canceled

        db.commit()
    except Exception:
        db.rollback()
        raise

    db.refresh(offer)
    return get_received_offer(db, offer.id, owner_user_id)


def reject_offer(
    db: Session,
    offer_id: str,
    owner_user_id: str,
) -> TradeRequestResponse:
    offer = _find_offer_for_owner(
        db=db,
        offer_id=offer_id,
        owner_user_id=owner_user_id,
        lock=True,
    )

    _ensure_pending(offer)

    try:
        offer.status_offer = StatusOffer.Rejected
        db.commit()
    except Exception:
        db.rollback()
        raise

    db.refresh(offer)
    return get_received_offer(db, offer.id, owner_user_id)


def _find_offer_for_owner(
    db: Session,
    offer_id: str,
    owner_user_id: str,
    lock: bool = False,
) -> Offer:
    query = (
        db.query(Offer)
        .join(
            TradeAnnouncement,
            Offer.target_announcement_id == TradeAnnouncement.id,
        )
        .filter(
            Offer.id == offer_id,
            TradeAnnouncement.user_id == owner_user_id,
        )
        .options(
            joinedload(Offer.user),
            joinedload(Offer.target_announcement)
            .joinedload(TradeAnnouncement.edition)
            .joinedload(Edition.book),
            joinedload(Offer.target_announcement)
            .joinedload(TradeAnnouncement.user),
            joinedload(Offer.offered_announcements)
            .joinedload(OfferedAnnouncements.announcement)
            .joinedload(TradeAnnouncement.edition)
            .joinedload(Edition.book),
            joinedload(Offer.offered_announcements)
            .joinedload(OfferedAnnouncements.announcement)
            .joinedload(TradeAnnouncement.user),
        )
    )

    if lock:
        query = query.with_for_update()

    offer = query.first()
    if offer is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Solicitação não encontrada ou sem permissão de acesso.",
        )

    return offer


def _ensure_pending(offer: Offer) -> None:
    if offer.status_offer != StatusOffer.Pending:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Apenas solicitações pendentes podem ser respondidas.",
        )


def _ensure_announcements_available(
    announcements: list[TradeAnnouncement],
) -> None:
    unavailable = [
        announcement.id
        for announcement in announcements
        if announcement is None or announcement.status != Status.Available
    ]

    if unavailable:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "Um ou mais anúncios envolvidos não estão mais disponíveis."
            ),
        )


def _offer_to_response(offer: Offer) -> TradeRequestResponse:
    requester = offer.user
    target = offer.target_announcement

    if requester is None or target is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="A solicitação possui relacionamentos inválidos.",
        )

    offered_books = [
        _announcement_to_book(relation.announcement)
        for relation in offer.offered_announcements
        if relation.announcement is not None
    ]

    return TradeRequestResponse(
        id=offer.id,
        requester=TradeRequestUserResponse(
            id=requester.id,
            name=requester.name,
            city=requester.city or "",
            state="",
            photoUrl=getattr(requester, "photo", None),
        ),
        requestedBook=_announcement_to_book(target),
        offeredBooks=offered_books,
        status=offer.status_offer,
        createdAt=offer.created_at,
    )


def _announcement_to_book(
    announcement: TradeAnnouncement,
) -> TradeRequestBookResponse:
    edition = announcement.edition
    book = edition.book if edition is not None else None
    owner = announcement.user

    return TradeRequestBookResponse(
        announcementId=announcement.id,
        title=book.title if book is not None else "Livro sem título",
        author=book.author if book is not None else "",
        publishYear=edition.publish_year if edition is not None else 0,
        city=owner.city if owner is not None and owner.city else "",
        state="",
        condition=(
            announcement.condition.value
            if announcement.condition is not None
            else ""
        ),
        coverUrl=announcement.real_photo_url,
    )
