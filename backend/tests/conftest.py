import sys
from pathlib import Path
from typing import Callable, Dict, Generator

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

pytest_plugins = ("tests.search_fixtures",)

# Make tests independent from invocation directory (e.g., repo root vs backend root).
BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.api.v1.announcements.router import router as announcements_router
from app.api.v1.users.router import router as users_router
from app.core.database import Base, get_db
from app.domain.announcements.models import Condition, Status, TradeAnnouncement
from app.domain.books.models import Book, Edition, Genre, Language
from app.domain.users.models import User



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


@pytest.fixture
def db_session() -> Generator[Session, None, None]:
    """Create an isolated in-memory database per test."""
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)

    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        engine.dispose()


@pytest.fixture
def users_client(db_session: Session) -> Generator[TestClient, None, None]:
    """Provide a TestClient with DB dependency overridden to use test DB."""
    app = FastAPI()
    app.include_router(users_router)

    def override_get_db() -> Generator[Session, None, None]:
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        with TestClient(app) as test_client:
            yield test_client
    finally:
        app.dependency_overrides.clear()



@pytest.fixture
def seed_announcement(db_session: Session) -> Callable[..., Dict[str, object]]:
    """Create a user/book/edition/announcement graph for tests."""
    counters = {"user": 0, "book": 0}

    def _seed(
        *,
        user: User | None = None,
        status: Status = Status.Available,
        title: str = "Livro",
        publish_year: int = 2000,
        photo_url: str | None = "https://example.com/book.jpg",
        condition: Condition = Condition.Good,
    ) -> Dict[str, object]:
        if user is None:
            counters["user"] += 1
            user = User(
                username=f"user_{counters['user']}",
                email=f"user_{counters['user']}@example.com",
                full_name=f"User {counters['user']}",
                cep="13000000",
            )
            db_session.add(user)
            db_session.flush()

        counters["book"] += 1
        book = Book(
            title=f"{title}_{counters['book']}",
            author="Autor Teste",
            genre=Genre.Fantasy,
            synopsis="Sinopse de teste",
        )
        db_session.add(book)
        db_session.flush()

        edition = Edition(
            book_id=book.id,
            publisher="Editora Teste",
            publish_year=publish_year,
            number_of_pages=123,
            language=Language.PT_br,
        )
        db_session.add(edition)
        db_session.flush()

        announcement = TradeAnnouncement(
            user_id=user.id,
            edition_id=edition.id,
            real_photo_url=photo_url,
            condition=condition,
            description="Descricao de teste",
            status=status,
        )
        db_session.add(announcement)
        db_session.flush()

        return {
            "user": user,
            "book": book,
            "edition": edition,
            "announcement": announcement,
        }

    return _seed