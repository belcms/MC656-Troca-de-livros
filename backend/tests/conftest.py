import sys
from pathlib import Path

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

# Make tests independent from invocation directory (e.g., repo root vs backend root).
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.api.v1.announcements.router import router as announcements_router
from app.core.database import get_db


@pytest.fixture
def fake_db():
    class DummyDB:
        pass
    return DummyDB()


@pytest.fixture
def app_with_router(fake_db):
    app = FastAPI()
    app.include_router(announcements_router)

    def override_get_db():
        yield fake_db

    app.dependency_overrides[get_db] = override_get_db
    return app


@pytest.fixture
def client(app_with_router):
    return TestClient(app_with_router)


@pytest.fixture
def client_no_raise(app_with_router):

    return TestClient(app_with_router, raise_server_exceptions=False)