import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.domain.announcements.models import Status, TradeAnnouncement
from app.domain.offer.models import Offer, StatusOffer
from app.domain.users.models import User


def _authenticate(client: TestClient, user: User) -> None:
    client.app.state.current_user = user


@pytest.mark.parametrize(
    ("method", "path"),
    [
        ("GET", "/api/v1/offers/received"),
        ("GET", "/api/v1/offers/offer-1"),
        ("PATCH", "/api/v1/offers/offer-1/accept"),
        ("PATCH", "/api/v1/offers/offer-1/reject"),
    ],
)
def test_received_offer_endpoints_require_authentication(
    offer_client: TestClient,
    method: str,
    path: str,
):
    response = offer_client.request(method, path)

    assert response.status_code == 401


def test_received_endpoint_returns_owner_requests_with_flutter_contract(
    offer_client: TestClient,
    seed_offer_scenario,
):
    data = seed_offer_scenario()
    _authenticate(offer_client, data["owner"])

    response = offer_client.get("/api/v1/offers/received")

    assert response.status_code == 200
    payload = response.json()

    assert [item["id"] for item in payload] == [
        data["main_offer"].id,
        data["competing_offer"].id,
        data["rejected_offer"].id,
    ]

    first = payload[0]
    assert set(first) == {
        "id",
        "requester",
        "requestedBook",
        "offeredBooks",
        "status",
        "createdAt",
    }
    assert first["status"] == "Pending"
    assert first["requester"]["name"] == "Pessoa Interessada"
    assert first["requestedBook"]["announcementId"] == data["target"].id
    assert len(first["offeredBooks"]) == 2


def test_received_endpoint_does_not_treat_received_as_offer_id(
    offer_client: TestClient,
    seed_offer_scenario,
):
    """Garante que a rota fixa /received vem antes de /{offer_id}."""
    data = seed_offer_scenario()
    _authenticate(offer_client, data["owner"])

    response = offer_client.get("/api/v1/offers/received")

    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_details_endpoint_returns_offer(
    offer_client: TestClient,
    seed_offer_scenario,
):
    data = seed_offer_scenario()
    _authenticate(offer_client, data["owner"])

    response = offer_client.get(
        f"/api/v1/offers/{data['main_offer'].id}",
    )

    assert response.status_code == 200
    payload = response.json()

    assert payload["id"] == data["main_offer"].id
    assert payload["status"] == "Pending"
    assert payload["requester"]["id"] == data["requester_main"].id
    assert payload["requestedBook"]["title"].startswith(
        "Flores para Algernon"
    )


def test_details_endpoint_ignores_forged_owner_id(
    offer_client: TestClient,
    seed_offer_scenario,
):
    data = seed_offer_scenario()
    _authenticate(offer_client, data["outsider"])

    response = offer_client.get(
        f"/api/v1/offers/{data['main_offer'].id}",
        params={"owner_user_id": data["owner"].id},
    )

    assert response.status_code == 404
    assert response.json()["detail"] == (
        "Solicitação não encontrada ou sem permissão de acesso."
    )


def test_details_endpoint_returns_404_for_unknown_offer(
    offer_client: TestClient,
    seed_offer_scenario,
):
    data = seed_offer_scenario()
    _authenticate(offer_client, data["owner"])

    response = offer_client.get("/api/v1/offers/offer-inexistente")

    assert response.status_code == 404


def test_accept_endpoint_applies_all_business_rules(
    offer_client: TestClient,
    db_session: Session,
    seed_offer_scenario,
):
    data = seed_offer_scenario()
    _authenticate(offer_client, data["owner"])

    response = offer_client.patch(
        f"/api/v1/offers/{data['main_offer'].id}/accept",
    )

    assert response.status_code == 200
    assert response.json()["status"] == "Accepted"

    db_session.expire_all()

    assert (
        db_session.get(Offer, data["main_offer"].id).status_offer
        == StatusOffer.Accepted
    )
    assert (
        db_session.get(Offer, data["competing_offer"].id).status_offer
        == StatusOffer.Canceled
    )
    assert (
        db_session.get(TradeAnnouncement, data["target"].id).status
        == Status.Reserved
    )


def test_accept_endpoint_returns_409_when_called_twice(
    offer_client: TestClient,
    seed_offer_scenario,
):
    data = seed_offer_scenario()
    _authenticate(offer_client, data["owner"])
    url = f"/api/v1/offers/{data['main_offer'].id}/accept"

    first = offer_client.patch(url)
    second = offer_client.patch(url)

    assert first.status_code == 200
    assert second.status_code == 409
    assert second.json()["detail"] == (
        "Apenas solicitações pendentes podem ser respondidas."
    )


def test_accept_endpoint_returns_409_when_book_is_unavailable(
    offer_client: TestClient,
    db_session: Session,
    seed_offer_scenario,
):
    data = seed_offer_scenario()
    _authenticate(offer_client, data["owner"])
    data["target"].status = Status.Reserved
    db_session.commit()

    response = offer_client.patch(
        f"/api/v1/offers/{data['main_offer'].id}/accept",
    )

    assert response.status_code == 409
    assert "não estão mais disponíveis" in response.json()["detail"]


def test_accept_endpoint_returns_404_for_wrong_owner(
    offer_client: TestClient,
    seed_offer_scenario,
):
    data = seed_offer_scenario()
    _authenticate(offer_client, data["outsider"])

    response = offer_client.patch(
        f"/api/v1/offers/{data['main_offer'].id}/accept",
    )

    assert response.status_code == 404


def test_reject_endpoint_rejects_pending_offer_without_reserving_books(
    offer_client: TestClient,
    db_session: Session,
    seed_offer_scenario,
):
    data = seed_offer_scenario()
    _authenticate(offer_client, data["owner"])

    response = offer_client.patch(
        f"/api/v1/offers/{data['main_offer'].id}/reject",
    )

    assert response.status_code == 200
    assert response.json()["status"] == "Rejected"

    db_session.expire_all()

    assert (
        db_session.get(Offer, data["main_offer"].id).status_offer
        == StatusOffer.Rejected
    )
    assert (
        db_session.get(TradeAnnouncement, data["target"].id).status
        == Status.Available
    )
    assert (
        db_session.get(
            TradeAnnouncement,
            data["offered_1984"].id,
        ).status
        == Status.Available
    )


def test_reject_endpoint_returns_409_for_already_rejected_offer(
    offer_client: TestClient,
    seed_offer_scenario,
):
    data = seed_offer_scenario()
    _authenticate(offer_client, data["owner"])

    response = offer_client.patch(
        f"/api/v1/offers/{data['rejected_offer'].id}/reject",
    )

    assert response.status_code == 409
    assert response.json()["detail"] == (
        "Apenas solicitações pendentes podem ser respondidas."
    )


def test_reject_endpoint_returns_404_for_wrong_owner(
    offer_client: TestClient,
    seed_offer_scenario,
):
    data = seed_offer_scenario()
    _authenticate(offer_client, data["outsider"])

    response = offer_client.patch(
        f"/api/v1/offers/{data['main_offer'].id}/reject",
    )

    assert response.status_code == 404
