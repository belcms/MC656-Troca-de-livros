from fastapi.testclient import TestClient
from fastapi import FastAPI
from sqlalchemy.orm import Session

from app.api.v1.announcements.router import router as announcements_router
from app.core.database import get_db


def test_update_book_saves_correct_fields(db_session: Session, seed_announcement):
    """
    Test that verifies if updating a book correctly persists all edited fields.

    Flow:
    1. Create test data using seed_announcement fixture
    2. Call PUT endpoint to update book
    3. Call GET endpoint to fetch updated data
    4. Assert all fields were saved correctly
    """

    # create app only with the router needed for the test
    app = FastAPI()
    app.include_router(announcements_router)

    # make API use in-memory test database
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    client = TestClient(app)

    # create test data directly in DB
    data = seed_announcement()
    announcement_id = data["announcement"].id

    # new values to update
    update_payload = {
        "title": "Novo Titulo",
        "author": "Novo Autor",
        "publisher": "Nova Editora",
        "genre": "Fantasy",
        "language": "PT-br",
        "publishYear": "2001",
        "pages": "321",
        "synopsis": "Nova sinopse de teste",
        "description": "Nova descricao de teste",
        "status": "Reserved",
        "condition": "Used",
        "real_photo_url": "https://example.com/new-cover.jpg"
    }

    # update book
    update_response = client.put(
        f"/api/v1/books/{announcement_id}",
        json=update_payload,
    )

    assert update_response.status_code == 200

    # fetch updated data
    details_response = client.get(f"/api/v1/books/details/{announcement_id}")

    assert details_response.status_code == 200

    updated = details_response.json()

    # verify fields were saved correctly
    assert updated["title"] == "Novo Titulo"
    assert updated["author"] == "Novo Autor"
    assert updated["publisher"] == "Nova Editora"
    assert updated["genre"] == "Fantasy"
    assert updated["language"] == "PT-br"
    assert updated["publishYear"] == 2001
    assert updated["pages"] == 321
    assert updated["synopsis"] == "Nova sinopse de teste"
    assert updated["description"] == "Nova descricao de teste"
    assert updated["status"] == "Reserved"
    assert updated["condition"] == "Used"
    assert updated["real_photo_url"] == "https://example.com/new-cover.jpg"