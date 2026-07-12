from datetime import datetime

from app.domain.offer.models import StatusOffer
from app.domain.offer.schemas import (
    OfferPydantic,
    OfferedAnnouncementPydantic,
    TradeRequestBookResponse,
    TradeRequestResponse,
    TradeRequestUserResponse,
)


def test_offered_announcement_schema_uses_camel_case_aliases():
    schema = OfferedAnnouncementPydantic(
        offered_announcement_id="announcement-1",
        offer_id="offer-1",
    )

    assert schema.model_dump(by_alias=True) == {
        "offeredAnnouncementId": "announcement-1",
        "offerId": "offer-1",
    }


def test_offer_schema_accepts_field_names_and_serializes_aliases():
    created_at = datetime(2026, 7, 12, 12, 0, 0)

    schema = OfferPydantic(
        id="offer-1",
        user_id="user-1",
        target_announcement_id="announcement-target",
        status_offer=StatusOffer.Pending,
        created_at=created_at,
        offered_announcements=[
            OfferedAnnouncementPydantic(
                offered_announcement_id="announcement-offered",
                offer_id="offer-1",
            )
        ],
    )

    payload = schema.model_dump(by_alias=True)

    assert payload["userId"] == "user-1"
    assert payload["targetAnnouncementId"] == "announcement-target"
    assert payload["statusOffer"] == StatusOffer.Pending
    assert payload["createdAt"] == created_at
    assert payload["offeredAnnouncements"][0]["offeredAnnouncementId"] == (
        "announcement-offered"
    )


def test_trade_request_response_serializes_contract_expected_by_flutter():
    created_at = datetime(2026, 7, 12, 12, 0, 0)

    response = TradeRequestResponse(
        id="offer-1",
        requester=TradeRequestUserResponse(
            id="requester-1",
            name="Pessoa Interessada",
            city="13000000",
            state="",
            photo_url=None,
        ),
        requested_book=TradeRequestBookResponse(
            announcement_id="target-1",
            title="Flores para Algernon",
            author="Daniel Keyes",
            publish_year=2000,
            city="13010000",
            state="",
            condition="Good",
            cover_url="https://example.com/target.jpg",
        ),
        offered_books=[
            TradeRequestBookResponse(
                announcement_id="offered-1",
                title="1984",
                author="George Orwell",
                publish_year=2009,
                city="11020000",
                state="",
                condition="Used",
                cover_url=None,
            )
        ],
        status=StatusOffer.Pending,
        created_at=created_at,
    )

    payload = response.model_dump(by_alias=True, mode="json")

    assert payload == {
        "id": "offer-1",
        "requester": {
            "id": "requester-1",
            "name": "Pessoa Interessada",
            "city": "13000000",
            "state": "",
            "photoUrl": None,
        },
        "requestedBook": {
            "announcementId": "target-1",
            "title": "Flores para Algernon",
            "author": "Daniel Keyes",
            "publishYear": 2000,
            "city": "13010000",
            "state": "",
            "condition": "Good",
            "coverUrl": "https://example.com/target.jpg",
        },
        "offeredBooks": [
            {
                "announcementId": "offered-1",
                "title": "1984",
                "author": "George Orwell",
                "publishYear": 2009,
                "city": "11020000",
                "state": "",
                "condition": "Used",
                "coverUrl": None,
            }
        ],
        "status": "Pending",
        "createdAt": "2026-07-12T12:00:00",
    }
