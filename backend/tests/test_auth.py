from datetime import date
from fastapi import FastAPI
from fastapi.testclient import TestClient
import pytest
from app.api.v1.auth.router import router as auth_router
from app.api.v1.users.router import router as users_router
from app.core.database import get_db
from app.domain.auth import services as auth_services
from app.domain.locations.models import Location as Location
from app.domain.users.models import AuthSession, User


@pytest.fixture
def auth_client(db_session):
    app = FastAPI()
    app.include_router(auth_router)
    app.include_router(users_router)
    def override_get_db():
        yield db_session
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as client:
        yield client


@pytest.fixture(autouse=True)
def location_lookup(db_session, monkeypatch):
    def fake_get_or_create(cep, db):
        clean_cep = str(cep).replace("-", "")
        existing = db.get(Location, clean_cep)
        if existing:
            return existing
        location = Location(
            cep=clean_cep,
            city="Campinas",
            state="SP",
            country="Brasil",
            lat=-22.9056,
            long=-47.0608,
        )
        db.add(location)
        db.flush()
        return location

    monkeypatch.setattr(
        auth_services.locations_services,
        "get_or_create_location_by_cep",
        fake_get_or_create,
    )


def payload(**changes):
    data = {"full_name": "Maria Silva", "nickname": "maria", "email": "maria@example.com",
            "password": "segredo123", "birth_date": "2000-01-01", "cep": "13000-000"}
    data.update(changes)
    return data


def test_register_hashes_password_and_authenticates(auth_client, db_session):
    client = auth_client
    response = client.post("/api/v1/auth/register", json=payload())
    assert response.status_code == 201
    assert response.json()["user"]["nickname"] == "maria"
    user = db_session.query(User).one()
    assert user.password_hash != "segredo123"
    assert user.cep == "13000000"
    assert user.cep_id == "13000000"
    assert user.location.city == "Campinas"
    assert user in user.location.users
    me = client.get("/api/v1/users/me", headers={"Authorization": f"Bearer {response.json()['access_token']}"})
    assert me.status_code == 200
    assert me.json()["email"] == "maria@example.com"


def test_registered_user_can_login_with_native_credentials(auth_client):
    client = auth_client
    registered = client.post("/api/v1/auth/register", json=payload())
    assert registered.status_code == 201

    logged_in = client.post(
        "/api/v1/auth/login",
        json={"email": "MARIA@example.com", "password": "segredo123"},
    )

    assert logged_in.status_code == 200
    assert logged_in.json()["token_type"] == "bearer"
    assert logged_in.json()["access_token"]
    assert logged_in.json()["refresh_token"]
    assert logged_in.json()["user"]["email"] == "maria@example.com"


def test_register_rejects_case_insensitive_duplicates(auth_client, db_session):
    client = auth_client
    assert client.post("/api/v1/auth/register", json=payload()).status_code == 201
    assert client.post("/api/v1/auth/register", json=payload(email="MARIA@example.com", nickname="outra")).status_code == 409
    assert client.post("/api/v1/auth/register", json=payload(email="outra@example.com", nickname="MARIA")).status_code == 409


def test_validation_and_invalid_credentials(auth_client, db_session):
    client = auth_client
    assert client.post("/api/v1/auth/register", json=payload(cep="123")).status_code == 422
    assert client.post("/api/v1/auth/register", json=payload(birth_date=str(date.today()))).status_code == 422
    client.post("/api/v1/auth/register", json=payload())
    assert client.post("/api/v1/auth/login", json={"email": "missing@example.com", "password": "wrong"}).status_code == 401
    assert client.post("/api/v1/auth/login", json={"email": "maria@example.com", "password": "wrong"}).status_code == 401


def test_refresh_rotates_and_logout_revokes(auth_client, db_session):
    client = auth_client
    session = client.post("/api/v1/auth/register", json=payload()).json()
    refreshed = client.post("/api/v1/auth/refresh", json={"refresh_token": session["refresh_token"]})
    assert refreshed.status_code == 200
    assert client.post("/api/v1/auth/refresh", json={"refresh_token": session["refresh_token"]}).status_code == 401
    new_token = refreshed.json()["refresh_token"]
    assert client.post("/api/v1/auth/logout", json={"refresh_token": new_token}).status_code == 204
    assert client.post("/api/v1/auth/refresh", json={"refresh_token": new_token}).status_code == 401
    assert db_session.query(AuthSession).count() == 2


def test_private_endpoints_require_authentication(auth_client, db_session):
    client = auth_client
    assert client.get("/api/v1/users/me").status_code == 401
    assert client.get("/api/v1/users/me/announcements").status_code == 401


@pytest.mark.parametrize("status_code", [404, 503])
def test_register_rejects_unknown_or_unavailable_location(
    auth_client,
    db_session,
    monkeypatch,
    status_code,
):
    def fail_location_lookup(cep, db):
        detail = (
            "Location not found for CEP"
            if status_code == 404
            else "Location service unavailable"
        )
        from fastapi import HTTPException

        raise HTTPException(status_code=status_code, detail=detail)

    monkeypatch.setattr(
        auth_services.locations_services,
        "get_or_create_location_by_cep",
        fail_location_lookup,
    )

    response = auth_client.post("/api/v1/auth/register", json=payload())

    assert response.status_code == status_code
    assert db_session.query(User).count() == 0
