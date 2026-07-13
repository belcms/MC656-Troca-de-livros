from __future__ import annotations

from typing import Generator

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api.v1.announcements.router import router as announcements_router
from app.core.database import get_db


@pytest.fixture
def announcements_search_client(db_session) -> Generator[TestClient, None, None]:
    app = FastAPI()
    app.include_router(announcements_router)

    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    try:
        with TestClient(app) as client:
            yield client
    finally:
        app.dependency_overrides.clear()


def test_search_route_returns_total_and_results_envelope(announcements_search_client, search_catalog):
    response = announcements_search_client.get(
        "/api/v1/announcements/search",
        params={"query": "Senhor dos Anéis"},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["total"] == 1
    assert len(payload["results"]) == 1
    assert payload["results"][0]["title"] == "Senhor dos Anéis"


def test_search_route_returns_multiple_harry_potter_results(announcements_search_client, search_catalog):
    response = announcements_search_client.get(
        "/api/v1/announcements/search",
        params={"query": "Hary"},
    )

    assert response.status_code == 200
    payload = response.json()
    titles = {item["title"] for item in payload["results"]}

    assert payload["total"] >= 2
    assert {"Harry Potter e a Pedra Filosofal", "Harry Potter e a Câmara Secreta"}.issubset(titles)