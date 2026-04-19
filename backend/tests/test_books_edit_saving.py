from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.main import app
from app.core.database import get_db


def get_dummy_announcement_id(client: TestClient):
    """
    Creates dummy data using the helper endpoint and
    returns one valid announcement id to be used in the test.
    """
    response = client.post("/create-dummy-data")

    # Ensure dummy data was created successfully
    assert response.status_code == 200

    body = response.json()
    ids = body.get("announcement_ids", [])

    # Ensure at least one announcement was created
    assert len(ids) > 0

    return ids[0]


def test_update_book_saves_correct_fields(db_session: Session):
    """
    Integration test that verifies if updating a book
    actually persists the new values in the database.

    Flow:
    1. Override DB dependency to use isolated in-memory test DB
    2. Create dummy announcement
    3. Send PUT request updating book fields
    4. Fetch updated book details
    5. Assert that all fields were correctly saved
    """

    # Override the database dependency so the API uses the test DB
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    # Create TestClient using the real FastAPI app
    client = TestClient(app)

    # Create initial dummy book/announcement
    announcement_id = get_dummy_announcement_id(client)

    # New values that should overwrite existing book data
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

    # Call the update endpoint
    update_response = client.put(
        f"/api/v1/books/{announcement_id}",
        json=update_payload,
    )

    # Verify request succeeded
    assert update_response.status_code == 200

    # Verify success message
    assert update_response.json()["message"] == "Book updated successfully"

    # Fetch updated book data
    details_response = client.get(f"/api/v1/books/details/{announcement_id}")

    # Ensure fetch succeeded
    assert details_response.status_code == 200

    updated = details_response.json()

    # Validate all fields were persisted correctly
    assert updated["id"] == announcement_id
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

    # Clean up dependency override so other tests are not affected
    app.dependency_overrides.clear()