# tests/test_announcements_services.py
import types
import pytest
from fastapi import HTTPException

from app.domain.announcements.services import (
    get_announcement_details,
    get_feed_announcements,
)
from app.domain.announcements.models import Condition, Status


def _obj(**kwargs):
    return types.SimpleNamespace(**kwargs)


def _mock_query_chain_first(db, first_result):
    query_obj = db.query.return_value
    filter_obj = query_obj.filter.return_value
    filter_obj.first.return_value = first_result


def _mock_feed_chain_all(db, all_result):
    query_obj = db.query.return_value

    query_obj.join.return_value = query_obj
    query_obj.options.return_value = query_obj
    query_obj.filter.return_value = query_obj
    query_obj.order_by.return_value = query_obj
    query_obj.all.return_value = all_result


def test_get_announcement_details_success(mocker):
    db = mocker.Mock()

    book = _obj(
        id="book-1",
        title="Dune",
        author="Frank Herbert",
        synopsis="A mythic and emotionally charged hero's journey.",
    )
    edition = _obj(
        id="edition-1",
        book_id="book-1",
        publisher="Chilton Books",
        publish_year=1965,
        book=book,
    )
    user = _obj(username="Neymar", cep="87654321")
    ann = _obj(
        id="ann-1",
        user_id="user-1",
        edition_id="edition-1",
        real_photo_url="http://img",
        condition=Condition.New,
        description="Nunca nem abri essa bomba",
        create_date=_obj(isoformat=lambda: "2026-04-14T12:00:00"),
        status=Status.Available,
        edition=edition,
        user=user,
    )

    _mock_query_chain_first(db, ann)

    result = get_announcement_details(db, "ann-1")

    assert result["id"] == "ann-1"
    assert result["book"]["title"] == "Dune"
    assert result["edition"]["publish_year"] == 1965
    assert result["user_name"] == "Neymar"
    assert result["condition"] == "New"
    assert result["status"] == "Available"


def test_get_announcement_details_not_found_404(mocker):
    db = mocker.Mock()
    _mock_query_chain_first(db, None)

    with pytest.raises(HTTPException) as exc:
        get_announcement_details(db, "does-not-exist")

    assert exc.value.status_code == 404
    assert exc.value.detail == "Announcement not found"


def test_get_announcement_details_db_failure_propagates(mocker):
    db = mocker.Mock()
    db.query.side_effect = RuntimeError("database connection lost")

    with pytest.raises(RuntimeError):
        get_announcement_details(db, "ann-1")


def test_get_announcement_details_missing_edition_breaks_currently(mocker):
    # Estado atual do codigo: edition None gera AttributeError.
    # Este teste ajuda a detectar necessidade de tratamento defensivo.
    db = mocker.Mock()
    ann = _obj(
        id="ann-1",
        user_id="user-1",
        edition_id="edition-1",
        real_photo_url=None,
        condition=Condition.Good,
        description=None,
        create_date=_obj(isoformat=lambda: "2026-04-14T12:00:00"),
        status=Status.Available,
        edition=None,
        user=_obj(username="u", cep="00000000"),
    )
    _mock_query_chain_first(db, ann)

    with pytest.raises(HTTPException) as exc:
        get_announcement_details(db, "ann-1")

    assert exc.value.status_code == 404
    assert exc.value.detail == "Edition information is missing for this announcement"


def test_get_feed_announcements_success(mocker):
    db = mocker.Mock()

    ann1 = _obj(
        id="ann-1",
        real_photo_url="http://img1",
        edition=_obj(
            publish_year=1965,
            book=_obj(title="Dune"),
        ),
        user=_obj(
            cep="87654321",
            cep_id="87654321",
        ),
        cep_id="87654321",
    )

    ann2 = _obj(
        id="ann-2",
        real_photo_url=None,
        edition=_obj(
            publish_year=1949,
            book=_obj(title="1984"),
        ),
        user=_obj(
            cep="12345678",
            cep_id="12345678",
        ),
        cep_id="12345678",
    )

    _mock_feed_chain_all(db, [ann1, ann2])

    result = get_feed_announcements(db, limit=20, offset=0)

    assert len(result) == 2
    dumped_0 = result[0].model_dump(by_alias=True)
    dumped_1 = result[1].model_dump(by_alias=True)

    assert dumped_0["id"] == "ann-1"
    assert dumped_0["title"] == "Dune"
    assert dumped_0["publishYear"] == 1965
    assert dumped_0["cep"] == "87654321"

    assert dumped_1["id"] == "ann-2"
    assert dumped_1["title"] == "1984"
    assert dumped_1["publishYear"] == 1949
    assert dumped_1["real_photo_url"] is None


def test_get_feed_announcements_empty_list(mocker):
    db = mocker.Mock()
    _mock_feed_chain_all(db, [])

    result = get_feed_announcements(db, limit=20, offset=0)

    assert result == []


def test_get_feed_announcements_without_location_uses_fallback(mocker):
    db = mocker.Mock()
    announcement = _obj(
        id="ann-without-location",
        real_photo_url=None,
        edition=_obj(
            publish_year=2000,
            book=_obj(title="Book without location"),
        ),
        user=_obj(cep=None, cep_id=None),
        cep_id=None,
        location=None,
    )
    _mock_feed_chain_all(db, [announcement])

    result = get_feed_announcements(db, limit=20, offset=0)

    assert result[0].cep == "Localização não informada"


def test_get_feed_announcements_db_failure_propagates(mocker):
    db = mocker.Mock()
    db.query.side_effect = RuntimeError("database read failed")

    with pytest.raises(RuntimeError):
        get_feed_announcements(db, limit=20, offset=0)
