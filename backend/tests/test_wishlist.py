def test_add_to_wishlist(users_client, db_session, seed_announcement):
    seeded = seed_announcement()
    user = seeded["user"]
    edition = seeded["edition"]

    response = users_client.post(f"/api/v1/users/{user.id}/wishlist/{edition.id}")
    assert response.status_code == 200
    
    payload = response.json()
    assert payload["user_id"] == user.id
    assert payload["edition_id"] == edition.id
    assert "id" in payload


def test_add_to_wishlist_duplicate(users_client, db_session, seed_announcement):
    seeded = seed_announcement()
    user = seeded["user"]
    edition = seeded["edition"]

    # First add
    users_client.post(f"/api/v1/users/{user.id}/wishlist/{edition.id}")
    # Second add
    response = users_client.post(f"/api/v1/users/{user.id}/wishlist/{edition.id}")
    
    assert response.status_code == 200
    payload = response.json()
    assert payload["user_id"] == user.id
    assert payload["edition_id"] == edition.id


def test_get_wishlist(users_client, db_session, seed_announcement):
    seeded1 = seed_announcement()
    user = seeded1["user"]
    edition1 = seeded1["edition"]

    # create a second edition, using the same user
    seeded2 = seed_announcement(user=user)
    edition2 = seeded2["edition"]

    users_client.post(f"/api/v1/users/{user.id}/wishlist/{edition1.id}")
    users_client.post(f"/api/v1/users/{user.id}/wishlist/{edition2.id}")

    response = users_client.get(f"/api/v1/users/{user.id}/wishlist")
    assert response.status_code == 200
    
    payload = response.json()
    assert len(payload) == 2
    edition_ids = {item["edition_id"] for item in payload}
    assert edition1.id in edition_ids
    assert edition2.id in edition_ids


def test_remove_from_wishlist(users_client, db_session, seed_announcement):
    seeded = seed_announcement()
    user = seeded["user"]
    edition = seeded["edition"]

    # Add first
    users_client.post(f"/api/v1/users/{user.id}/wishlist/{edition.id}")

    # Then remove
    response = users_client.delete(f"/api/v1/users/{user.id}/wishlist/{edition.id}")
    assert response.status_code == 200
    assert response.json()["message"] == "Item removed from wishlist"

    # Verify it's empty
    get_resp = users_client.get(f"/api/v1/users/{user.id}/wishlist")
    assert len(get_resp.json()) == 0


def test_remove_from_wishlist_not_found(users_client, db_session, seed_announcement):
    seeded = seed_announcement()
    user = seeded["user"]
    edition = seeded["edition"]

    response = users_client.delete(f"/api/v1/users/{user.id}/wishlist/{edition.id}")
    assert response.status_code == 404
    assert response.json()["detail"] == "Item not found in wishlist"
