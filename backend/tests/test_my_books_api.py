from app.domain.announcements.models import Status
from app.domain.users.models import User


def test_get_user_announcements_endpoint_returns_cards(users_client, db_session, seed_announcement):
    first = seed_announcement(status=Status.Reserved, title="CleanCode", publish_year=2008)
    user = first["user"]
    second = seed_announcement(user=user, status=Status.Available, title="Refactoring", publish_year=1999)
    seed_announcement(status=Status.Available, title="AnotherUserBook")
    db_session.commit()

    response = users_client.get(f"/api/v1/users/{user.id}/announcements")

    assert response.status_code == 200
    payload = response.json()
    assert len(payload) == 2
    assert [item["status"] for item in payload] == ["Available", "Reserved"]
    assert payload[0]["id"] == second["announcement"].id
    assert payload[1]["id"] == first["announcement"].id
    assert set(payload[0].keys()) == {"id", "title", "publish_year", "real_photo_url", "status", "location", "cover_photo"}
    assert payload[0]["location"] != "Localização não informada"


def test_get_user_announcements_endpoint_returns_empty_list_for_non_existent_user(users_client):
    response = users_client.get("/api/v1/users/non-existent-user-id/announcements")

    assert response.status_code == 200
    assert response.json() == []


def test_get_user_announcements_endpoint_returns_empty_list_for_existing_user_without_announcements(
    users_client, db_session
):
    user = User(
        username="without_books",
        email="without_books@example.com",
        full_name="Without Books",
        cep="13000123",
    )
    db_session.add(user)
    db_session.commit()

    response_existing_user_without_announcements = users_client.get(
        f"/api/v1/users/{user.id}/announcements"
    )
    assert response_existing_user_without_announcements.status_code == 200
    assert response_existing_user_without_announcements.json() == []
