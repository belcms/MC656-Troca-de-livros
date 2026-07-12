from datetime import date
from fastapi import FastAPI
from fastapi.testclient import TestClient
import pytest
from app.api.v1.auth.router import router as auth_router
from app.api.v1.users.router import router as users_router
from app.core.database import get_db
from app.domain.users.models import AuthSession, User
from app.domain.auth import services as auth_services


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
    me = client.get("/api/v1/users/me", headers={"Authorization": f"Bearer {response.json()['access_token']}"})
    assert me.status_code == 200
    assert me.json()["email"] == "maria@example.com"


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


def test_google_login_requires_onboarding_and_then_issues_session(db_session, monkeypatch):
    monkeypatch.setattr(auth_services, "verify_google", lambda _: {
        "sub": "google-123", "email": "google@example.com", "email_verified": True,
        "name": "Google User",
    })
    pending = auth_services.google_login(db_session, "valid-token")
    assert pending["requires_onboarding"] is True
    completed = auth_services.complete_google(
        db_session, pending["onboarding_token"], "google_user", date(2000, 1, 1), "13000000"
    )
    assert completed["user"].nickname == "google_user"
    assert db_session.query(User).one().google_subject == "google-123"


def test_google_links_existing_verified_email(db_session, monkeypatch):
    existing = User(username="local", username_normalized="local", email="same@example.com",
                    email_normalized="same@example.com", full_name="Local", cep="13000000",
                    birth_date=date(2000, 1, 1), onboarding_complete=True)
    db_session.add(existing)
    db_session.commit()
    monkeypatch.setattr(auth_services, "verify_google", lambda _: {
        "sub": "google-linked", "email": "SAME@example.com", "email_verified": True,
        "name": "Google User",
    })
    result = auth_services.google_login(db_session, "valid-token")
    assert result["user"].id == existing.id
    assert existing.google_subject == "google-linked"
