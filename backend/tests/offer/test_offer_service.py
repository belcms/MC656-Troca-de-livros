from datetime import datetime

import pytest
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.domain.announcements.models import Status, TradeAnnouncement
from app.domain.offer.models import Offer, StatusOffer
from app.services.offer_service import (
    accept_offer,
    get_received_offer,
    list_received_offers,
    reject_offer,
)


def test_list_received_offers_returns_only_owner_offers_in_descending_order(
    db_session: Session,
    seed_offer_scenario,
):
    data = seed_offer_scenario()

    result = list_received_offers(
        db=db_session,
        owner_user_id=data["owner"].id,
    )

    assert [item.id for item in result] == [
        data["main_offer"].id,
        data["competing_offer"].id,
        data["rejected_offer"].id,
    ]
    assert data["outsider_offer"].id not in [item.id for item in result]


def test_list_received_offers_returns_empty_list_for_owner_without_offers(
    db_session: Session,
    seed_offer_scenario,
):
    data = seed_offer_scenario()

    result = list_received_offers(
        db=db_session,
        owner_user_id=data["requester_main"].id,
    )

    assert result == []


def test_get_received_offer_maps_requester_target_and_offered_books(
    db_session: Session,
    seed_offer_scenario,
):
    data = seed_offer_scenario()

    response = get_received_offer(
        db=db_session,
        offer_id=data["main_offer"].id,
        owner_user_id=data["owner"].id,
    )

    assert response.id == data["main_offer"].id
    assert response.status == StatusOffer.Pending
    assert response.requester.id == data["requester_main"].id
    assert response.requester.name == "Pessoa Interessada"
    assert response.requester.city == "11020000"

    assert response.requested_book.announcement_id == data["target"].id
    assert response.requested_book.title.startswith("Flores para Algernon")
    assert response.requested_book.publish_year == 2000
    assert response.requested_book.condition == "Good"

    assert {
        book.announcement_id for book in response.offered_books
    } == {
        data["offered_1984"].id,
        data["offered_descartes"].id,
    }


@pytest.mark.parametrize(
    "offer_key,owner_key",
    [
        ("main_offer", "outsider"),
        ("outsider_offer", "owner"),
    ],
)
def test_get_received_offer_hides_offers_from_non_owner(
    db_session: Session,
    seed_offer_scenario,
    offer_key: str,
    owner_key: str,
):
    data = seed_offer_scenario()

    with pytest.raises(HTTPException) as error:
        get_received_offer(
            db=db_session,
            offer_id=data[offer_key].id,
            owner_user_id=data[owner_key].id,
        )

    assert error.value.status_code == 404
    assert error.value.detail == (
        "Solicitação não encontrada ou sem permissão de acesso."
    )


def test_get_received_offer_returns_404_for_unknown_offer(
    db_session: Session,
    seed_offer_scenario,
):
    data = seed_offer_scenario()

    with pytest.raises(HTTPException) as error:
        get_received_offer(
            db=db_session,
            offer_id="offer-inexistente",
            owner_user_id=data["owner"].id,
        )

    assert error.value.status_code == 404


def test_accept_offer_accepts_main_reserves_books_and_cancels_competitor(
    db_session: Session,
    seed_offer_scenario,
):
    data = seed_offer_scenario()

    response = accept_offer(
        db=db_session,
        offer_id=data["main_offer"].id,
        owner_user_id=data["owner"].id,
    )

    db_session.expire_all()

    main_offer = db_session.get(Offer, data["main_offer"].id)
    competing_offer = db_session.get(Offer, data["competing_offer"].id)
    rejected_offer = db_session.get(Offer, data["rejected_offer"].id)
    outsider_offer = db_session.get(Offer, data["outsider_offer"].id)

    assert response.status == StatusOffer.Accepted
    assert main_offer.status_offer == StatusOffer.Accepted
    assert competing_offer.status_offer == StatusOffer.Canceled

    # Ofertas que não concorrem pelo mesmo anúncio não são alteradas.
    assert rejected_offer.status_offer == StatusOffer.Rejected
    assert outsider_offer.status_offer == StatusOffer.Pending

    for announcement_key in (
        "target",
        "offered_1984",
        "offered_descartes",
    ):
        announcement = db_session.get(
            TradeAnnouncement,
            data[announcement_key].id,
        )
        assert announcement.status == Status.Reserved

    # O livro da oferta concorrente não participa da troca aceita.
    competing_book = db_session.get(
        TradeAnnouncement,
        data["offered_hobbit"].id,
    )
    assert competing_book.status == Status.Available


def test_accept_offer_does_not_cancel_already_finalized_competitor(
    db_session: Session,
    seed_offer_scenario,
):
    data = seed_offer_scenario()
    data["competing_offer"].status_offer = StatusOffer.Rejected
    db_session.commit()

    accept_offer(
        db=db_session,
        offer_id=data["main_offer"].id,
        owner_user_id=data["owner"].id,
    )

    db_session.expire_all()
    competing_offer = db_session.get(Offer, data["competing_offer"].id)

    assert competing_offer.status_offer == StatusOffer.Rejected


@pytest.mark.parametrize(
    "status",
    [
        StatusOffer.Accepted,
        StatusOffer.Rejected,
        StatusOffer.Canceled,
    ],
)
def test_accept_offer_rejects_non_pending_offer(
    db_session: Session,
    seed_offer_scenario,
    status: StatusOffer,
):
    data = seed_offer_scenario()
    data["main_offer"].status_offer = status
    db_session.commit()

    with pytest.raises(HTTPException) as error:
        accept_offer(
            db=db_session,
            offer_id=data["main_offer"].id,
            owner_user_id=data["owner"].id,
        )

    assert error.value.status_code == 409
    assert error.value.detail == (
        "Apenas solicitações pendentes podem ser respondidas."
    )


@pytest.mark.parametrize(
    "announcement_key",
    [
        "target",
        "offered_1984",
        "offered_descartes",
    ],
)
def test_accept_offer_rejects_when_any_involved_announcement_is_unavailable(
    db_session: Session,
    seed_offer_scenario,
    announcement_key: str,
):
    data = seed_offer_scenario()
    data[announcement_key].status = Status.Reserved
    db_session.commit()

    with pytest.raises(HTTPException) as error:
        accept_offer(
            db=db_session,
            offer_id=data["main_offer"].id,
            owner_user_id=data["owner"].id,
        )

    assert error.value.status_code == 409
    assert "não estão mais disponíveis" in error.value.detail

    db_session.expire_all()
    main_offer = db_session.get(Offer, data["main_offer"].id)
    assert main_offer.status_offer == StatusOffer.Pending


def test_accept_offer_requires_target_owner(
    db_session: Session,
    seed_offer_scenario,
):
    data = seed_offer_scenario()

    with pytest.raises(HTTPException) as error:
        accept_offer(
            db=db_session,
            offer_id=data["main_offer"].id,
            owner_user_id=data["outsider"].id,
        )

    assert error.value.status_code == 404


def test_reject_offer_changes_only_offer_status(
    db_session: Session,
    seed_offer_scenario,
):
    data = seed_offer_scenario()

    response = reject_offer(
        db=db_session,
        offer_id=data["main_offer"].id,
        owner_user_id=data["owner"].id,
    )

    db_session.expire_all()

    assert response.status == StatusOffer.Rejected
    assert (
        db_session.get(Offer, data["main_offer"].id).status_offer
        == StatusOffer.Rejected
    )
    assert (
        db_session.get(Offer, data["competing_offer"].id).status_offer
        == StatusOffer.Pending
    )

    for announcement_key in (
        "target",
        "offered_1984",
        "offered_descartes",
    ):
        announcement = db_session.get(
            TradeAnnouncement,
            data[announcement_key].id,
        )
        assert announcement.status == Status.Available


@pytest.mark.parametrize(
    "status",
    [
        StatusOffer.Accepted,
        StatusOffer.Rejected,
        StatusOffer.Canceled,
    ],
)
def test_reject_offer_rejects_non_pending_offer(
    db_session: Session,
    seed_offer_scenario,
    status: StatusOffer,
):
    data = seed_offer_scenario()
    data["main_offer"].status_offer = status
    db_session.commit()

    with pytest.raises(HTTPException) as error:
        reject_offer(
            db=db_session,
            offer_id=data["main_offer"].id,
            owner_user_id=data["owner"].id,
        )

    assert error.value.status_code == 409


def test_reject_offer_requires_target_owner(
    db_session: Session,
    seed_offer_scenario,
):
    data = seed_offer_scenario()

    with pytest.raises(HTTPException) as error:
        reject_offer(
            db=db_session,
            offer_id=data["main_offer"].id,
            owner_user_id=data["outsider"].id,
        )

    assert error.value.status_code == 404
