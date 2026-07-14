# tests/test_announcements_router.py
import pytest
from fastapi import HTTPException

import app.api.v1.announcements.router as announcements_router_module


def test_details_route_success(client, monkeypatch):
    def fake_service(db, id):
        return {
            "id": id,
            "user_id": "u-1",
            "user_name": "Neymar",
            "user_cep": "87654321",
            "edition_id": "e-1",
            "real_photo_url": None,
            "condition": "New",
            "description": "desc",
            "create_date": "2026-04-14T12:00:00",
            "status": "Available",
            "edition": {
                "id": "e-1",
                "book_id": "b-1",
                "publisher": "Chilton Books",
                "publish_year": 1965,
            },
            "book": {
                "id": "b-1",
                "title": "Dune",
                "author": "Frank Herbert",
                "synopsis": "syn",
            },
        }

    monkeypatch.setattr(announcements_router_module, "get_announcement_details", fake_service)

    response = client.get("/api/v1/announcements/details/ann-1")
    assert response.status_code == 200
    body = response.json()
    assert body["id"] == "ann-1"
    assert body["book"]["title"] == "Dune"


def test_details_route_404(client, monkeypatch):
    def fake_service(db, id):
        raise HTTPException(status_code=404, detail="Announcement not found")

    monkeypatch.setattr(announcements_router_module, "get_announcement_details", fake_service)

    response = client.get("/api/v1/announcements/details/not-found")
    assert response.status_code == 404
    assert response.json()["detail"] == "Announcement not found"


def test_details_route_500_on_unhandled_exception(client_no_raise, monkeypatch):
    def fake_service(db, id):
        raise RuntimeError("db down")

    monkeypatch.setattr(announcements_router_module, "get_announcement_details", fake_service)

    response = client_no_raise.get("/api/v1/announcements/details/ann-1")
    assert response.status_code == 500


def test_feed_route_success_and_contract(client, monkeypatch):
    def fake_feed_service(
        db,
        limit,
        offset,
        start_year=None,
        end_year=None,
        conditions=None,
        genres=None,
        current_user_id=None,
        sort_by_distance=False,
        max_distance_km=None,
    ):
        return [
            {
                "id": "ann-1",
                "title": "Dune",
                "publishYear": 1965,
                "cep": "87654321",
                "real_photo_url": "http://img",
                "condition": "New",
                "distanceKm": None,
            }
        ]

    monkeypatch.setattr(
        announcements_router_module,
        "get_feed_announcements",
        fake_feed_service,
    )

    response = client.get(
        "/api/v1/announcements/feed?limit=20&offset=0"
    )

    assert response.status_code == 200
    assert response.json() == [
        {
            "id": "ann-1",
            "title": "Dune",
            "publishYear": 1965,
            "cep": "87654321",
            "real_photo_url": "http://img",
            "condition": "New",
            "cover_photo": "",
            "distanceKm": None,
        }
    ]

def test_feed_route_passes_distance_sorting_params(client, monkeypatch):
    captured = {}

    def fake_feed_service(
        db,
        limit,
        offset,
        start_year=None,
        end_year=None,
        conditions=None,
        genres=None,
        current_user_id=None,
        sort_by_distance=False,
        max_distance_km=None,
    ):
        captured["limit"] = limit
        captured["offset"] = offset
        captured["start_year"] = start_year
        captured["end_year"] = end_year
        captured["conditions"] = conditions
        captured["genres"] = genres
        captured["current_user_id"] = current_user_id
        captured["sort_by_distance"] = sort_by_distance
        captured["max_distance_km"] = max_distance_km

        return [
            {
                "id": "ann-1",
                "title": "Dune",
                "publishYear": 1965,
                "cep": "Campinas - SP",
                "real_photo_url": "http://img",
                "condition": "New",
                "distanceKm": 12.4,
            }
        ]

    monkeypatch.setattr(
        announcements_router_module,
        "get_feed_announcements",
        fake_feed_service,
    )

    response = client.get(
        "/api/v1/announcements/feed"
        "?limit=10"
        "&offset=5"
        "&current_user_id=user-1"
        "&sort_by_distance=true"
    )

    assert response.status_code == 200
    assert captured == {
        "limit": 10,
        "offset": 5,
        "start_year": None,
        "end_year": None,
        "conditions": None,
        "genres": None,
        "current_user_id": "user-1",
        "sort_by_distance": True,
        "max_distance_km": None,
    }
    assert response.json() == [
        {
            "id": "ann-1",
            "title": "Dune",
            "publishYear": 1965,
            "cep": "Campinas - SP",
            "real_photo_url": "http://img",
            "condition": "New",
            "cover_photo": "",
            "distanceKm": 12.4,
        }
    ]


def test_feed_route_query_validation_limit_too_high(client):
    response = client.get("/api/v1/announcements/feed?limit=999&offset=0")
    assert response.status_code == 422


def test_feed_route_query_validation_offset_negative(client):
    response = client.get("/api/v1/announcements/feed?limit=20&offset=-1")
    assert response.status_code == 422
