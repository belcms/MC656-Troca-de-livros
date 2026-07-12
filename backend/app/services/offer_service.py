from fastapi import HTTPException, status
from sqlalchemy.orm import Session, joinedload, selectinload
from app.api.v1.announcements.schemas import MyBooksCardResponse
from app.domain.announcements.models import Status, TradeAnnouncement
from app.domain.books.models import Edition
from app.domain.offer.models import (
    Offer,
    OfferedAnnouncements,
    StatusOffer,
)
from app.domain.offer.schemas import (
    TradeRequestBookResponse,
    TradeRequestResponse,
    TradeRequestUserResponse,
    OfferCreate
)
from typing import List, Sequence



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


def list_received_offers(
    db: Session,
    owner_user_id: str,
) -> List[TradeRequestResponse]:
    """
    Lista as ofertas recebidas pelos anúncios do usuário informado.

    As ofertas são retornadas da mais recente para a mais antiga.
    """
    offers = (
        db.query(Offer)
        .join(
            TradeAnnouncement,
            Offer.target_announcement_id == TradeAnnouncement.id,
        )
        .filter(
            TradeAnnouncement.user_id == owner_user_id,
        )
        .options(*_offer_loading_options())
        .order_by(Offer.created_at.desc())
        .all()
    )

    return [_offer_to_response(offer) for offer in offers]


def get_received_offer(
    db: Session,
    offer_id: str,
    owner_user_id: str,
) -> TradeRequestResponse:
    """
    Obtém os detalhes de uma oferta recebida.

    A oferta somente é retornada caso o usuário informado seja dono
    do anúncio que recebeu a proposta.
    """
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
    """
    Aceita uma proposta de troca.

    Regras:
    - somente o dono do anúncio pode aceitar;
    - somente ofertas pendentes podem ser aceitas;
    - todos os anúncios envolvidos precisam estar disponíveis;
    - o anúncio desejado e os anúncios oferecidos são reservados;
    - outras ofertas pendentes para o mesmo anúncio são canceladas.
    """
    offer = _find_offer_for_owner(
        db=db,
        offer_id=offer_id,
        owner_user_id=owner_user_id,
        lock=True,
    )

    _ensure_pending(offer)

    target_announcement = offer.target_announcement

    offered_announcements = [
        relation.announcement
        for relation in offer.offered_announcements
        if relation.announcement is not None
    ]

    if target_announcement is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="A solicitação não possui um anúncio de destino válido.",
        )

    _ensure_announcements_available(
        [target_announcement, *offered_announcements],
    )

    try:
        offer.status_offer = StatusOffer.Accepted
        target_announcement.status = Status.Reserved

        for announcement in offered_announcements:
            announcement.status = Status.Reserved

        competing_offers = (
            db.query(Offer)
            .filter(
                Offer.target_announcement_id == target_announcement.id,
                Offer.id != offer.id,
                Offer.status_offer == StatusOffer.Pending,
            )
            .with_for_update(of=Offer)
            .all()
        )

        for competing_offer in competing_offers:
            competing_offer.status_offer = StatusOffer.Canceled

        db.commit()

    except HTTPException:
        db.rollback()
        raise

    except Exception:
        db.rollback()
        raise

    return get_received_offer(
        db=db,
        offer_id=offer.id,
        owner_user_id=owner_user_id,
    )


def reject_offer(
    db: Session,
    offer_id: str,
    owner_user_id: str,
) -> TradeRequestResponse:
    """
    Recusa uma proposta de troca.

    A recusa altera somente o estado da oferta. Os anúncios continuam
    disponíveis.
    """
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

    except HTTPException:
        db.rollback()
        raise

    except Exception:
        db.rollback()
        raise

    return get_received_offer(
        db=db,
        offer_id=offer.id,
        owner_user_id=owner_user_id,
    )


def _find_offer_for_owner(
    db: Session,
    offer_id: str,
    owner_user_id: str,
    lock: bool = False,
) -> Offer:
    """
    Busca uma oferta destinada a um anúncio do usuário informado.

    Quando lock=True, a função primeiro bloqueia somente a linha da tabela
    Offer. Em seguida, carrega os relacionamentos em uma segunda consulta.

    Isso evita o erro do PostgreSQL:

    FOR UPDATE cannot be applied to the nullable side of an outer join
    """
    if lock:
        locked_offer = (
            db.query(Offer)
            .join(
                TradeAnnouncement,
                Offer.target_announcement_id == TradeAnnouncement.id,
            )
            .filter(
                Offer.id == offer_id,
                TradeAnnouncement.user_id == owner_user_id,
            )
            .with_for_update(of=Offer)
            .one_or_none()
        )

        if locked_offer is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(
                    "Solicitação não encontrada "
                    "ou sem permissão de acesso."
                ),
            )

    offer = (
        db.query(Offer)
        .join(
            TradeAnnouncement,
            Offer.target_announcement_id == TradeAnnouncement.id,
        )
        .filter(
            Offer.id == offer_id,
            TradeAnnouncement.user_id == owner_user_id,
        )
        .options(*_offer_loading_options())
        .one_or_none()
    )

    if offer is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "Solicitação não encontrada "
                "ou sem permissão de acesso."
            ),
        )

    return offer


def _offer_loading_options():
    """
    Define os relacionamentos que precisam ser carregados para montar
    a resposta enviada ao frontend.

    selectinload é usado na coleção offered_announcements para evitar
    uma consulta principal muito grande com múltiplos LEFT OUTER JOINs.
    """
    return (
        joinedload(Offer.user),

        joinedload(Offer.target_announcement)
        .joinedload(TradeAnnouncement.edition)
        .joinedload(Edition.book),

        joinedload(Offer.target_announcement)
        .joinedload(TradeAnnouncement.user),

        selectinload(Offer.offered_announcements)
        .joinedload(OfferedAnnouncements.announcement)
        .joinedload(TradeAnnouncement.edition)
        .joinedload(Edition.book),

        selectinload(Offer.offered_announcements)
        .joinedload(OfferedAnnouncements.announcement)
        .joinedload(TradeAnnouncement.user),
    )


def _ensure_pending(offer: Offer) -> None:
    """
    Garante que a oferta ainda pode ser respondida.
    """
    if offer.status_offer != StatusOffer.Pending:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Apenas solicitações pendentes podem ser respondidas.",
        )


def _ensure_announcements_available(
    announcements: Sequence[TradeAnnouncement],
) -> None:
    """
    Garante que todos os anúncios envolvidos ainda estejam disponíveis.
    """
    unavailable_ids: list[str] = []

    for announcement in announcements:
        if announcement is None:
            unavailable_ids.append("anúncio inexistente")
            continue

        if announcement.status != Status.Available:
            unavailable_ids.append(announcement.id)

    if unavailable_ids:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "Um ou mais anúncios envolvidos não estão mais disponíveis. "
                f"Anúncios: {', '.join(unavailable_ids)}"
            ),
        )


def _offer_to_response(
    offer: Offer,
) -> TradeRequestResponse:
    """
    Converte uma entidade Offer para o schema consumido pelo Flutter.
    """
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

    requester_name = (
        requester.full_name
        or requester.username
        or "Usuário"
    )

    return TradeRequestResponse(
        id=offer.id,
        requester=TradeRequestUserResponse(
            id=requester.id,
            name=requester_name,
            city=requester.cep or "",
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
    """
    Converte um TradeAnnouncement para o formato de livro utilizado
    na tela de solicitações.
    """
    edition = announcement.edition
    book = edition.book if edition is not None else None
    owner = announcement.user

    title = (
        book.title
        if book is not None and book.title
        else "Livro sem título"
    )

    author = (
        book.author
        if book is not None and book.author
        else ""
    )

    publish_year = (
        edition.publish_year
        if edition is not None and edition.publish_year is not None
        else 0
    )

    owner_location = (
        owner.cep
        if owner is not None and owner.cep
        else ""
    )

    condition = (
        announcement.condition.value
        if announcement.condition is not None
        else ""
    )

    return TradeRequestBookResponse(
        announcementId=announcement.id,
        title=title,
        author=author,
        publishYear=publish_year,
        city=owner_location,
        state="",
        condition=condition,
        coverUrl=announcement.real_photo_url,
    )
