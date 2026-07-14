import pytest
from datetime import datetime, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.database import Base
from app.domain.announcements.models import TradeAnnouncement, Status, Condition
from app.domain.users.models import User
from app.domain.books.models import Book, Edition, Genre
from app.domain.announcements.services import get_feed_announcements

@pytest.fixture(scope="function")
def db_session():
    """
    Create a new database that will be used just for the tests.
    """
    engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=engine)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    yield db
    db.close()
    Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def populated_db(db_session):
    """
    Create the data for the tests and put it on the db
    """
    user1 = User(username="user-1", email="user-1@example.com", full_name="User 1", cep="Campinas - SP")
    book1 = Book(title="Throne of Glass", author="Sarah J Maas", genre=Genre.Fantasy)
    book2 = Book(title="Hunger Games", author="Suzane Collins", genre=Genre.Fantasy)
    
    db_session.add_all([user1, book1, book2])
    db_session.flush() 
    
    ed1 = Edition(book_id=book1.id, publish_year=2012, publisher="Record")
    ed2 = Edition(book_id=book2.id, publish_year=2010, publisher="Rocco")
    
    db_session.add_all([ed1, ed2])
    db_session.flush()

    now = datetime.utcnow()
    
    ann_old = TradeAnnouncement(id="ann-1", user_id=user1.id, edition_id=ed1.id, status=Status.Available, condition=Condition.Used, create_date=now - timedelta(days=5))
    ann_new = TradeAnnouncement(id="ann-2", user_id=user1.id, edition_id=ed2.id, status=Status.Available, condition=Condition.New, create_date=now)
    ann_traded = TradeAnnouncement(id="ann-3", user_id=user1.id, edition_id=ed1.id, status=Status.Traded, condition=Condition.Good, create_date=now)

    db_session.add_all([ann_old, ann_new, ann_traded])
    db_session.commit()
    
    return db_session 

def test_feed_status(populated_db):
    """
    Check if the function is returning just the announcements with status as Available.
    """
    results = get_feed_announcements(db=populated_db, limit=10, offset=0)
    
    assert len(results) == 2, "The announcement with status 'Traded' wasn't ignored."

def test_feed_ordering(populated_db):
    """
    Check if the results are ordered by create time.
    """
    results = get_feed_announcements(db=populated_db, limit=10, offset=0)
    
    assert results[0].id == "ann-2", "The first announcement isn't the most recent."
    assert results[1].id == "ann-1", "The second announcement isn't the oldest."

def test_feed_data(populated_db):
    """
    Check if the data results are correct.
    """
    results = get_feed_announcements(db=populated_db, limit=10, offset=0)
    
    assert results[0].title == "Hunger Games"
    assert results[0].publish_year == 2010
    assert results[0].cep == "Campinas - SP"