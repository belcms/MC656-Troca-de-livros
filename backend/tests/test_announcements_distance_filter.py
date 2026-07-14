from __future__ import annotations

import math
from datetime import datetime
from types import SimpleNamespace
from unittest.mock import MagicMock

import pytest

from app.domain.announcements.models import Condition
from app.domain.announcements.services import get_feed_announcements
from app.domain.users.models import User
from app.domain.announcements.models import TradeAnnouncement


EARTH_RADIUS_KM = 6371.0
MAX_DISTANCE_KM = 50.0


def _latitude_for_distance(distance_km: float) -> float:
    # transforma a distancia em uma diferenca de latitude
    return math.degrees(distance_km / EARTH_RADIUS_KM)


def _create_location(distance_km: float):
    # cria uma localizacao na distancia que queremos testar
    return SimpleNamespace(
        lat=_latitude_for_distance(distance_km),
        long=0.0,
        city="Cidade de teste",
        state="SP",
        cep="00000000",
    )


def _create_announcement(distance_km: float):
    #cria um anuncio fake com distancia informada
    book = SimpleNamespace(
        title=f"Livro a {distance_km} km",
    )

    edition = SimpleNamespace(
        publish_year=2020,
        book=book,
    )

    location = _create_location(distance_km)

    owner = SimpleNamespace(
        id="announcement-owner",
        cep_id="00000000",
        cep="00000000",
        location=location,
    )

    return SimpleNamespace(
        id=f"announcement-{distance_km}",
        user_id="announcement-owner",
        edition=edition,
        condition=Condition.Good,
        real_photo_url=None,
        photos=[],
        location=location,
        user=owner,
        cep_id="00000000",
        create_date=datetime(2026, 1, 1),
    )


def _create_mock_db(announcement):
    # cria um mock do banco para nao precisar usar o banco real
    db = MagicMock()

    current_user = SimpleNamespace(
        id="current-user",
        location=SimpleNamespace(
            lat=0.0,
            long=0.0,
        ),
    )

    announcement_query = MagicMock()
    user_query = MagicMock()

    #Deixa a query de anuncios funcionar em cadeia
    announcement_query.join.return_value = announcement_query
    announcement_query.options.return_value = announcement_query
    announcement_query.filter.return_value = announcement_query
    announcement_query.order_by.return_value = announcement_query
    announcement_query.limit.return_value = announcement_query
    announcement_query.offset.return_value = announcement_query
    announcement_query.all.return_value = [announcement]

    # configura a busca do usuario atual
    user_query.options.return_value = user_query
    user_query.filter.return_value = user_query
    user_query.first.return_value = current_user

    def query_side_effect(model):
        if model is User:
            return user_query

        if model is TradeAnnouncement:
            return announcement_query

        raise AssertionError(f"Consulta inesperada para o modelo: {model}")

    db.query.side_effect = query_side_effect

    return db


@pytest.mark.parametrize(
    ("announcement_distance", "expected_to_be_returned"),
    [
        pytest.param(
            49.9,
            True,
            id="immediately-below-limit-49.9-km",
        ),
        pytest.param(
            50.0,
            True,
            id="exactly-at-limit-50.0-km",
        ),
        pytest.param(
            50.1,
            False,
            id="immediately-above-limit-50.1-km",
        ),
    ],
)
def test_feed_filters_announcements_at_distance_boundary(
    announcement_distance,
    expected_to_be_returned,
):
    #cria um anuncio na distancia que esta sendo testada
    announcement = _create_announcement(announcement_distance)
    db = _create_mock_db(announcement)

    #aplica o filtro com limite de 50 km
    results = get_feed_announcements(
        db=db,
        limit=20,
        offset=0,
        current_user_id="current-user",
        max_distance_km=MAX_DISTANCE_KM,
    )

    returned_ids = {item.id for item in results}

    #verifca se o anuncio deveria ou nao aparecer
    assert (
        announcement.id in returned_ids
    ) is expected_to_be_returned