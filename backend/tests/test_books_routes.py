from fastapi.testclient import TestClient
from app.main import app

# creates a test client to simulate requests to the api
client = TestClient(app)


# helper function to create dummy data and return one valid announcement id
def get_dummy_announcement_id():

    # calls endpoint that creates dummy data in the database
    response = client.post("/create-dummy-data")

    # verifies request worked correctly
    assert response.status_code == 200

    body = response.json()

    ids = body.get("announcement_ids", [])

    # ensures at least one announcement id was created
    assert len(ids) > 0

    # returns the first id to be used in other tests
    return ids[0]


# verifies if dummy data endpoint works correctly
def test_create_dummy_data():

    # calls endpoint responsible for creating test data
    response = client.post("/create-dummy-data")

    # checks successful response
    assert response.status_code == 200

    body = response.json()

    # verifies expected fields in response
    assert "message" in body
    assert "announcement_ids" in body

    # verifies ids list exists and contains values
    assert isinstance(body["announcement_ids"], list)
    assert len(body["announcement_ids"]) > 0


# verifies if book details can be fetched using a valid id
def test_get_book_details_success():

    # gets a valid id from dummy data
    announcement_id = get_dummy_announcement_id()

    # sends request to fetch announcement details
    response = client.get(f"/api/v1/books/details/{announcement_id}")

    # checks successful response
    assert response.status_code == 200

    body = response.json()

    # verifies expected fields exist in response
    assert body["id"] == announcement_id
    assert "title" in body
    assert "author" in body
    assert "publisher" in body
    assert "genre" in body
    assert "language" in body
    assert "publishYear" in body
    assert "pages" in body
    assert "synopsis" in body
    assert "description" in body
    assert "status" in body
    assert "condition" in body
    assert "real_photo_url" in body


# verifies correct error when id does not exist
def test_get_book_details_not_found():

    # sends request with invalid id
    response = client.get("/api/v1/books/details/id-inexistente")

    # checks correct error response
    assert response.status_code == 404

    # verifies error message
    assert response.json()["detail"] == "Announcement not found"


# verifies if book update works correctly and data is persisted
def test_update_book_success():

    # gets a valid id from dummy data
    announcement_id = get_dummy_announcement_id()

    payload = {

        # new values to update announcement
        "title": "Animal Farm",
        "author": "George Orwell",
        "publisher": "Test Publisher",
        "genre": "Fantasy",
        "language": "PT-br",
        "publishYear": "2000",
        "pages": "123",
        "synopsis": "test synopsis",
        "description": "test description",
        "status": "Reserved",
        "condition": "Used",
        "real_photo_url": "https://example.com/test.jpg"

    }

    # sends request to update book data
    response = client.put(
        f"/api/v1/books/{announcement_id}",
        json=payload
    )

    # checks if update request succeeded
    assert response.status_code == 200

    # verifies success message
    assert response.json()["message"] == "Book updated successfully"


    # fetches updated data to confirm persistence in database
    details_response = client.get(
        f"/api/v1/books/details/{announcement_id}"
    )

    assert details_response.status_code == 200

    updated = details_response.json()

    # verifies updated values match payload
    assert updated["title"] == "Animal Farm"
    assert updated["author"] == "George Orwell"
    assert updated["publisher"] == "Test Publisher"
    assert updated["genre"] == "Fantasy"
    assert updated["language"] == "PT-br"
    assert updated["publishYear"] == 2000
    assert updated["pages"] == 123
    assert updated["synopsis"] == "test synopsis"
    assert updated["description"] == "test description"
    assert updated["status"] == "Reserved"
    assert updated["condition"] == "Used"
    assert updated["real_photo_url"] == "https://example.com/test.jpg"


# verifies correct error when trying to update a non existing id
def test_update_book_not_found():

    payload = {

        # minimal payload to trigger update attempt
        "title": "1984"

    }

    # sends request using invalid id
    response = client.put(
        "/api/v1/books/id-inexistente",
        json=payload
    )

    # checks correct error response
    assert response.status_code == 404

    # verifies error message
    assert response.json()["detail"] == "Announcement not found"