from app.domain.announcements.models import Status
from app.domain.users import services
from app.domain.users.models import User


def test_get_user_announcements_returns_only_user_data(db_session, seed_announcement):
    owner_data_1 = seed_announcement(status=Status.Available, title="OwnerBook")
    owner = owner_data_1["user"]
    owner_data_2 = seed_announcement(user=owner, status=Status.Reserved, title="OwnerBook")
    seed_announcement(status=Status.Available, title="OtherUserBook")
    db_session.commit()

    result = services.get_user_announcements(db=db_session, user_id=owner.id)

    assert len(result) == 2
    assert {item["id"] for item in result} == {
        owner_data_1["announcement"].id,
        owner_data_2["announcement"].id,
    }
    assert all(
        set(item.keys())
        == {"id", "title", "publish_year", "real_photo_url", "status", "location", "cover_photo"}
        for item in result
    )
    assert all(item["location"] == "Campinas - SP" for item in result)


def test_get_user_announcements_orders_by_status_priority(db_session, seed_announcement):
    seeded = seed_announcement(status=Status.Traded)
    user = seeded["user"]
    seed_announcement(user=user, status=Status.Reserved)
    seed_announcement(user=user, status=Status.Available)
    db_session.commit()

    result = services.get_user_announcements(db=db_session, user_id=user.id)

    assert [item["status"] for item in result] == [
        Status.Available,
        Status.Reserved,
        Status.Traded,
    ]


def test_get_user_announcements_returns_empty_list_for_user_without_books(db_session):
    user = User(
        username="empty_user",
        email="empty_user@example.com",
        full_name="Empty User",
        cep="13000001",
    )
    db_session.add(user)
    db_session.commit()

    result = services.get_user_announcements(db=db_session, user_id=user.id)

    assert result == []

