import pytest
import asyncio
from fastapi import HTTPException

from app.domain.announcements import services as announcement_services
from app.domain.announcements.models import Condition, Status, TradeAnnouncement
from app.domain.announcements.schemas import TradeAnnouncementPydantic
from app.domain.books.models import Book, Edition, Genre, Language
from app.domain.locations.models import location as Location
from app.domain.locations.schemas import LocationPydantic
from app.domain.locations import services as location_services
from app.domain.users.models import User


def _seed_graph(db_session, *, title="Livro", cep_id=None):
    user = User(
        username=f"user-{title}",
        email=f"{title}@example.com",
        full_name="User Teste",
    )
    db_session.add(user)
    db_session.flush()

    book = Book(
        title=title,
        author="Autor",
        genre=Genre.Romance,
        synopsis="Sinopse",
    )
    db_session.add(book)
    db_session.flush()

    edition = Edition(
        book_id=book.id,
        publisher="Editora",
        publish_year=2020,
        number_of_pages=100,
        language=Language.PT_br,
    )
    db_session.add(edition)
    db_session.flush()

    announcement = TradeAnnouncement(
        user_id=user.id,
        edition_id=edition.id,
        cep_id=cep_id,
        real_photo_url="https://example.com/book.jpg",
        condition=Condition.Good,
        description="Descricao",
        status=Status.Available,
    )
    db_session.add(announcement)
    db_session.flush()

    return user, book, edition, announcement


def _location(cep, city, state, lat, long):
    return Location(
        cep=cep,
        city=city,
        state=state,
        country="Brasil",
        district=None,
        lat=lat,
        long=long,
    )


def test_create_announcement_with_valid_cep_associates_location(db_session, monkeypatch):
    user, _, edition, _ = _seed_graph(db_session, title="Criacao")

    def fake_get_or_create(cep, db):
        loc = _location("13000000", "Campinas", "SP", -22.9, -47.06)
        db.merge(loc)
        db.flush()
        return loc

    monkeypatch.setattr(
        announcement_services.locations_services,
        "get_or_create_location_by_cep",
        fake_get_or_create,
    )

    body = TradeAnnouncementPydantic(
        editionId=edition.id,
        cep="13000-000",
        condition=Condition.Good,
        description="Com localizacao",
        coverUrl="https://example.com/photo.jpg",
    )

    result = announcement_services.create_announcement(user.id, body, db_session)

    assert result["data"].cep_id == "13000000"
    assert db_session.get(Location, "13000000").city == "Campinas"


def test_create_announcement_with_invalid_cep_does_not_save_announcement(db_session, monkeypatch):
    user, _, edition, _ = _seed_graph(db_session, title="Invalido")
    before_count = db_session.query(TradeAnnouncement).count()

    def fake_get_or_create(cep, db):
        raise HTTPException(status_code=404, detail="Location not found for CEP")

    monkeypatch.setattr(
        announcement_services.locations_services,
        "get_or_create_location_by_cep",
        fake_get_or_create,
    )

    body = TradeAnnouncementPydantic(
        editionId=edition.id,
        cep="99999999",
        condition=Condition.Good,
        description="CEP ruim",
        coverUrl="https://example.com/photo.jpg",
    )

    with pytest.raises(HTTPException):
        announcement_services.create_announcement(user.id, body, db_session)

    assert db_session.query(TradeAnnouncement).count() == before_count


def test_update_announcement_with_valid_cep_replaces_location(db_session, monkeypatch):
    _, _, _, announcement = _seed_graph(db_session, title="Edicao")

    def fake_get_or_create(cep, db):
        loc = _location("01001000", "Sao Paulo", "SP", -23.55, -46.63)
        db.merge(loc)
        db.flush()
        return loc

    monkeypatch.setattr(
        announcement_services.locations_services,
        "get_or_create_location_by_cep",
        fake_get_or_create,
    )

    announcement_services.update_book(announcement.id, {"cep_id": "01001-000"}, db_session)

    db_session.refresh(announcement)
    assert announcement.cep_id == "01001000"


def test_sort_locations_by_distance_keeps_invalid_entries_last():
    reference = LocationPydantic(
        cep="13000000",
        city="Campinas",
        state="SP",
        country="Brasil",
        district=None,
        lat=-22.9,
        long=-47.06,
    )
    near = LocationPydantic(
        cep="13000001",
        city="Campinas",
        state="SP",
        country="Brasil",
        district=None,
        lat=-22.91,
        long=-47.07,
    )
    far = LocationPydantic(
        cep="01001000",
        city="Sao Paulo",
        state="SP",
        country="Brasil",
        district=None,
        lat=-23.55,
        long=-46.63,
    )

    result = asyncio.run(
        location_services.sort_posts_by_distance_from_A(
            reference,
            [{"location": far}, {"location": None}, {"location": near}],
        )
    )

    assert result[0]["location"] == near
    assert result[1]["location"] == far
    assert result[2]["location"] is None
