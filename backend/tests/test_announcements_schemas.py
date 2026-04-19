# tests/test_announcements_schemas.py
import pytest
from pydantic import ValidationError

from app.api.v1.announcements.schemas import (
    TradeAnnouncementBase,
    TradeAnnouncementResponse,
    FeedAnnouncementResponse,
    MyBooksCardResponse,
)
from app.domain.announcements.models import Condition, Status


def test_trade_announcement_base_valid():
    data = TradeAnnouncementBase(
        edition_id="ed-1",
        real_photo_url=None,
        condition=Condition.New,
        description="desc",
        status=Status.Available,
    )
    assert data.edition_id == "ed-1"
    assert data.condition == Condition.New


def test_trade_announcement_response_valid():
    data = TradeAnnouncementResponse(
        id="ann-1",
        user_id="user-1",
        edition_id="ed-1",
        real_photo_url=None,
        condition=Condition.Good,
        description=None,
        status=Status.Reserved,
        create_date="2026-04-14T12:00:00",
    )
    assert data.id == "ann-1"
    assert data.status == Status.Reserved


def test_feed_schema_accepts_alias_publish_year():
    model = FeedAnnouncementResponse(
        id="ann-1",
        title="Dune",
        publishYear=1965,
        cep="87654321",
        real_photo_url=None,
    )
    dumped = model.model_dump(by_alias=True)
    assert dumped["publishYear"] == 1965
    assert dumped["title"] == "Dune"


def test_feed_schema_missing_required_field_fails():
    with pytest.raises(ValidationError):
        FeedAnnouncementResponse(
            id="ann-1",
            publishYear=1965,
            cep="87654321",
        )


def test_my_books_schema_valid():
    model = MyBooksCardResponse(
        id="ann-1",
        title="Dune",
        publish_year=1965,
        real_photo_url=None,
        status=Status.Traded,
    )
    assert model.status == Status.Traded