from fastapi.params import Body, Depends
from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status
from app.domain.announcements import models
from app.domain.announcements.models import Status
from app.api.v1.announcements.schemas import FeedAnnouncementResponse
from app.domain.books.models import Edition, Book
from app.domain.users.models import User
from app.domain.books import models as books_models
from app.domain.announcements import models as announcements_models
from app.domain.users import models as users_models
from app.core.database import get_db
import app.domain.books.schemas as books_schemas
import app.domain.announcements.schemas as announcements_schemas

import math




#excluir, não ideal (apenas para create_dummy_data/teste)
import app.domain.locations.services as locations_services

def get_announcement_details(db: Session, id: str):
    """
    Retrieve complete details of a trade announcement by its ID.

    This function queries the database for a specific `TradeAnnouncement`
    and loads its related entities:
    - User
    - Book edition
    - Book

    If any of these entities are missing, an HTTP 404 exception is raised.

    Args:
        db (Session):
            An active SQLAlchemy database session used to perform queries
            and access persisted data.

        id (str):
            The unique identifier of the trade announcement to retrieve.

    Returns:
        dict:
            A dictionary containing all relevant announcement data,
            structured for easy consumption (e.g., by a REST API or frontend).
            Includes:

            - Announcement data:
                id, user_id, edition_id, description, condition, status,
                creation date, real photo URL

            - User data:
                user_name, user_cep

            - Edition data:
                id, book_id, publisher, publish_year

            - Book data:
                id, title, author, synopsis

    Raises:
        HTTPException (404):
            - If the announcement is not found
            - If the associated edition is missing
            - If the associated book is missing
            - If the associated user is missing
    """

    announcements = db.query(models.TradeAnnouncement).filter(models.TradeAnnouncement.id == id).first()
    
    if not announcements:
        raise HTTPException(status_code=404, detail="Announcement not found")
    
    edition = announcements.edition

    if not edition:
        raise HTTPException(status_code=404, detail="Edition information is missing for this announcement")
    
    book = edition.book

    if not book:
        raise HTTPException(status_code=404, detail="Book information is missing for this edition")
    
    user = announcements.user

    if not user:
         raise HTTPException(status_code=404, detail="User information is missing")
    

    text = {
        "id": announcements.id,
        "user_id": announcements.user_id,
        "user_name": user.username,
        "cep_id": getattr(announcements, "cep_id", None),
        "edition_id": announcements.edition_id,
        "real_photo_url": announcements.real_photo_url,
        "condition": announcements.condition.value,
        "description": announcements.description,
        "create_date": announcements.create_date.isoformat(),
        "status": announcements.status.value,
        "edition": {
            "id": edition.id,
            "book_id": edition.book_id,
            "publisher": edition.publisher,
            "publish_year": edition.publish_year
        },
        "book": {
            "id": book.id,
            "title": book.title,
            "author": book.author,
            "synopsis": book.synopsis
        }
    }
    
    return text

def get_feed_announcements(
    db: Session,
    limit: int = 20,
    offset: int = 0,
    current_user_id: str | None = None,
    sort_by_distance: bool = False,
):
    """
    Retrieves a paginated list of available trade announcements for the feed.

    Default behavior:
    - returns available announcements ordered from newest to oldest.

    Distance behavior:
    - when sort_by_distance=True and current_user_id is provided,
      announcements are ordered by distance from the current user.
    - announcements without a calculable distance are placed at the end.
    - create_date is used as a tiebreaker, with newer announcements first.
    - pagination is applied after distance ordering.
    """

    base_query = (
        db.query(models.TradeAnnouncement)
        .options(
            joinedload(models.TradeAnnouncement.edition).joinedload(
                Edition.book
            ),
            joinedload(models.TradeAnnouncement.user),
            joinedload(models.TradeAnnouncement.location),
        )
        .filter(models.TradeAnnouncement.status == Status.Available)
    )

    def build_location_label(announcement):
        if getattr(announcement, "location", None):
            city = getattr(announcement.location, "city", None)
            state = getattr(announcement.location, "state", None)

            if city and state:
                return f"{city} - {state}"

            if city:
                return city

            if state:
                return state

        return (
            getattr(announcement, "cep_id", None)
            or getattr(announcement.user, "cep_id", None)
            or getattr(announcement.user, "cep", None)
            or "Localização não informada"
        )

    def build_response(announcement, distance_km: float | None = None):
        return FeedAnnouncementResponse(
            id=announcement.id,
            title=announcement.edition.book.title,
            real_photo_url=announcement.real_photo_url,
            publishYear=announcement.edition.publish_year,
            cep=build_location_label(announcement),
            distanceKm=(
                round(distance_km, 1)
                if distance_km is not None
                else None
            ),
        )

    def has_coordinates(location) -> bool:
        return (
            location is not None
            and getattr(location, "lat", None) is not None
            and getattr(location, "long", None) is not None
        )

    def calculate_distance_km(origin_location, target_location) -> float:
        earth_radius_km = 6371.0

        origin_lat = math.radians(float(origin_location.lat))
        origin_long = math.radians(float(origin_location.long))
        target_lat = math.radians(float(target_location.lat))
        target_long = math.radians(float(target_location.long))

        delta_lat = target_lat - origin_lat
        delta_long = target_long - origin_long

        haversine_value = (
            math.sin(delta_lat / 2) ** 2
            + math.cos(origin_lat)
            * math.cos(target_lat)
            * math.sin(delta_long / 2) ** 2
        )

        angular_distance = 2 * math.atan2(
            math.sqrt(haversine_value),
            math.sqrt(1 - haversine_value),
        )

        return earth_radius_km * angular_distance

    if not sort_by_distance or not current_user_id:
        announcements = (
            base_query.order_by(
                models.TradeAnnouncement.create_date.desc()
            )
            .limit(limit)
            .offset(offset)
            .all()
        )

        return [
            build_response(announcement)
            for announcement in announcements
        ]

    current_user = (
        db.query(User)
        .options(joinedload(User.location))
        .filter(User.id == current_user_id)
        .first()
    )

    if current_user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuário não encontrado.",
        )

    user_location = getattr(current_user, "location", None)

    if not has_coordinates(user_location):
        announcements = (
            base_query.order_by(
                models.TradeAnnouncement.create_date.desc()
            )
            .limit(limit)
            .offset(offset)
            .all()
        )

        return [
            build_response(announcement)
            for announcement in announcements
        ]

    announcements = base_query.all()

    announcements_with_distance = []

    for announcement in announcements:
        announcement_location = getattr(
            announcement,
            "location",
            None,
        )

        distance_km = None

        if has_coordinates(announcement_location):
            distance_km = calculate_distance_km(
                origin_location=user_location,
                target_location=announcement_location,
            )

        announcements_with_distance.append(
            {
                "announcement": announcement,
                "distance_km": distance_km,
            }
        )

    announcements_with_distance.sort(
        key=lambda item: (
            item["distance_km"] is None,
            item["distance_km"]
            if item["distance_km"] is not None
            else float("inf"),
            -item["announcement"].create_date.timestamp()
            if item["announcement"].create_date is not None
            else 0,
        )
    )

    paginated_items = announcements_with_distance[
        offset : offset + limit
    ]

    return [
        build_response(
            announcement=item["announcement"],
            distance_km=item["distance_km"],
        )
        for item in paginated_items
    ]
    

def map_genre(value: str):
    """
    Map a string value to the corresponding Genre enum.

    This function takes a genre name as a string and returns the matching
    `books_models.Genre` enum. If the provided value does not match any
    known genre, it defaults to `Genre.Romance`.

    Args:
        value (str): The string representation of the genre.

    Returns:
        books_models.Genre: The mapped genre enum.
    """
    mapping = {
        "Fantasy": books_models.Genre.Fantasy,
        "Romance": books_models.Genre.Romance,
        "Sci_fic": books_models.Genre.Sci_fic,
        "Non_fiction": books_models.Genre.Non_fiction,
        "Biography": books_models.Genre.Biography,
        "Graphic_novel": books_models.Genre.Graphic_novel,
        "Horror": books_models.Genre.Horror,
        "Self_help": books_models.Genre.Self_help,
        "Thriller": books_models.Genre.Thriller,
        "Education": books_models.Genre.Education,
    }
    return mapping.get(value, books_models.Genre.Romance)


def map_language(value: str):
    """
    Map a string value to the corresponding Language enum.

    This function takes a language name as a string and returns the matching
    `books_models.Language` enum. If the provided value does not match any
    known language, it defaults to `Language.PT_br`.

    Args:
        value (str): The string representation of the language.

    Returns:
        books_models.Language: The mapped language enum.
    """
    mapping = {
        "PT-br": books_models.Language.PT_br,
        "En": books_models.Language.En,
        "Espanhol": books_models.Language.Espanhol,
    }
    return mapping.get(value, books_models.Language.PT_br)


def map_status(value: str):
    """
    Map a string value to the corresponding Status enum.

    This function takes a status name as a string and returns the matching
    `announcements_models.Status` enum. If the provided value does not match
    any known status, it defaults to `Status.Available`.

    Args:
        value (str): The string representation of the status.

    Returns:
        announcements_models.Status: The mapped status enum.
    """
    mapping = {
        "Available": announcements_models.Status.Available,
        "Reserved": announcements_models.Status.Reserved,
        "Traded": announcements_models.Status.Traded,
    }
    return mapping.get(value, announcements_models.Status.Available)


def map_condition(value: str):
    """
    Map a string value to the corresponding Condition enum.

    This function takes a condition name as a string and returns the matching
    `announcements_models.Condition` enum. If the provided value does not match
    any known condition, it defaults to `Condition.New`.

    Args:
        value (str): The string representation of the condition.

    Returns:
        announcements_models.Condition: The mapped condition enum.
    """
    mapping = {
        "New": announcements_models.Condition.New,
        "Good": announcements_models.Condition.Good,
        "Used": announcements_models.Condition.Used,
        "Worn": announcements_models.Condition.Worn,
    }
    return mapping.get(value, announcements_models.Condition.New)


async def create_dummy_data(db: Session = Depends(get_db)):
    """
    Populate the database with initial dummy data for testing purposes.

    This function checks if any trade announcements currently exist in the database.
    If they do, it returns early. Otherwise, it creates and persists two dummy users,
    two dummy books, two dummy editions, and two trade announcements linked to them.

    Args:
        db (Session): The active SQLAlchemy database session. Defaults to `get_db`.

    Returns:
        dict: A dictionary containing a success or status message and a list
        of the created (or existing) announcement IDs.
    """
    existing = db.query(announcements_models.TradeAnnouncement).first()

    if existing:
        announcements = db.query(announcements_models.TradeAnnouncement).all()
        return {
            "message": "Dummy data already exists!",
            "announcement_ids": [a.id for a in announcements]
        }
    loc1 = await locations_services.get_location_by_cep("07115000", db)
    loc2 = await locations_services.get_location_by_cep("07115000", db)

    user1 = users_models.User(
        username="rafael",
        email="rafael@example.com",
        full_name="Rafael Feltrin",
        cep_id= loc1.cep #Just for now while we don't integrate with a Sedex API
    )
    user2 = users_models.User(
        username="Neymar",
        email="neymar@example.com",
        full_name="Neymar Jr.",
        cep_id= loc2.cep #Just for now while we don't integrate with a Sedex API
    )
    db.add_all([user1, user2])
    db.commit()
    db.refresh(user1)
    db.refresh(user2)

    book1 = books_models.Book(
        title="1984",
        author="George Orwell",
        genre=books_models.Genre.Sci_fic,
        synopsis="Dystopian social science fiction novel and cautionary tale."
    )
    book2 = books_models.Book(
        title="Dune",
        author="Frank Herbert",
        genre=books_models.Genre.Sci_fic,
        synopsis="A mythic and emotionally charged hero's journey."
    )
    db.add_all([book1, book2])
    db.commit()
    db.refresh(book1)
    db.refresh(book2)

    edition1 = books_models.Edition(
        book_id=book1.id,
        publisher="Secker & Warburg",
        publish_year=1949,
        number_of_pages=328,
        language=books_models.Language.En
    )
    edition2 = books_models.Edition(
        book_id=book2.id,
        publisher="Chilton Books",
        publish_year=1965,
        number_of_pages=412,
        language=books_models.Language.En
    )
    db.add_all([edition1, edition2])
    db.commit()
    db.refresh(edition1)
    db.refresh(edition2)

    announcement1 = announcements_models.TradeAnnouncement(
        user_id=user1.id,
        edition_id=edition1.id,
        cep_id = loc1.cep,
        real_photo_url="https://m.media-amazon.com/images/I/91g5gcjTxsL._SY522_.jpg",
        condition=announcements_models.Condition.Good,
        description="Muito muito bom, cuido muito bem",
        status=announcements_models.Status.Available
    )
    announcement2 = announcements_models.TradeAnnouncement(
        user_id=user2.id,
        edition_id=edition2.id,
        cep_id = loc1.cep,
        real_photo_url="https://m.media-amazon.com/images/I/81zN7udGRUL._SL1500_.jpg",
        condition=announcements_models.Condition.New,
        description="Nunca nem abri essa bomba",
        status=announcements_models.Status.Available
    )
    db.add_all([announcement1, announcement2])
    db.commit()
    db.refresh(announcement1)
    db.refresh(announcement2)

    return {
        "message": "Dummy data created successfully!",
        "announcement_ids": [announcement1.id, announcement2.id]
    }

def get_book_details(id: str, db: Session = Depends(get_db)):
    """
    Retrieve detailed information about a book from a specific announcement.

    This function queries the database for a `TradeAnnouncement` by its ID and
    extracts flattened data spanning the announcement, its related edition, and
    the core book details.

    Args:
        id (str): The unique identifier of the trade announcement.
        db (Session): The active SQLAlchemy database session. Defaults to `get_db`.

    Returns:
        dict: A flattened dictionary containing combined details of the announcement,
        book, and edition (e.g., title, author, publisher, status, real_photo_url).

    Raises:
        HTTPException (404): If no announcement is found with the provided ID.
    """
    announcement = (
        db.query(announcements_models.TradeAnnouncement)
        .filter(announcements_models.TradeAnnouncement.id == id)
        .first()
    )

    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")

    edition = announcement.edition
    book = edition.book

    return {
        "id": announcement.id,
        "title": book.title,
        "author": book.author,
        "publisher": edition.publisher,
        "genre": book.genre.value,
        "language": edition.language.value,
        "publishYear": edition.publish_year,
        "pages": edition.number_of_pages,
        "synopsis": book.synopsis,
        "description": announcement.description,
        "status": announcement.status.value,
        "condition": announcement.condition.value,
        "real_photo_url": announcement.real_photo_url,
    }

def update_book(
    id: str,
    body: dict = Body(...),
    db: Session = Depends(get_db),
):
    """
    Update the details of an existing book, edition, and announcement.

    This function fetches an existing trade announcement by its ID and updates
    its fields, as well as the fields of the associated edition and book, based
    on the provided dictionary payload. It uses mapping functions to safely
    convert string values to enums where necessary.

    Args:
        id (str): The unique identifier of the trade announcement to update.
        body (dict): A dictionary containing the fields and values to update.
        db (Session): The active SQLAlchemy database session. Defaults to `get_db`.

    Returns:
        dict: A dictionary containing a success message.

    Raises:
        HTTPException (404): If no announcement is found with the provided ID.
    """
    announcement = (
        db.query(announcements_models.TradeAnnouncement)
        .filter(announcements_models.TradeAnnouncement.id == id)
        .first()
    )

    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")

    edition = announcement.edition
    book = edition.book

    book.title = body.get("title", book.title)
    book.author = body.get("author", book.author)
    book.synopsis = body.get("synopsis", book.synopsis)
    book.genre = map_genre(body.get("genre", book.genre.value))

    edition.publisher = body.get("publisher", edition.publisher)
    edition.language = map_language(body.get("language", edition.language.value))

    if body.get("publishYear"):
        edition.publish_year = int(body["publishYear"])

    if body.get("pages"):
        edition.number_of_pages = int(body["pages"])

    announcement.description = body.get("description", announcement.description)
    announcement.real_photo_url = body.get("real_photo_url", announcement.real_photo_url)
 # Rratar o CEP antes de salvar para evitar erro de Chave Estrangeira
    if "cep_id" in body:
        clean_cep = locations_services.normalize_cep(body.get("cep_id"))
        if clean_cep is None:
            announcement.cep_id = None
        else:
            loc = locations_services.get_or_create_location_by_cep(clean_cep, db)
            announcement.cep_id = loc.cep
    announcement.status = map_status(body.get("status", announcement.status.value))
    announcement.condition = map_condition(body.get("condition", announcement.condition.value))

    db.commit()

    return {"message": "Book updated successfully"}

def create_book(body: books_schemas.BookPydantic, db: Session = Depends(get_db),):
    """
    Create a new book record in the database.

    This function accepts a Pydantic model containing book data, converts it into
    an SQLAlchemy model, and persists it to the database.

    Args:
        body (books_schemas.BookPydantic): The validated Pydantic model containing
            the book data.
        db (Session): The active SQLAlchemy database session. Defaults to `get_db`.

    Returns:
        dict: A dictionary containing the created SQLAlchemy book object, a success
        message, and the newly generated book ID.
    """
    #transforma o body que está em um obj pydantic em um modelo do SQLAlchemy para persistir no banco
    book = books_models.Book(**body.model_dump(exclude={"id"}))

    db.add(book)
    db.commit()
    db.refresh(book)

    return {"data": book,
            "message": "Book created successfully",
             "bookId": book.id}

def create_edition(book_id: str, body: books_schemas.EditionPydantic, db: Session = Depends(get_db)):
    """
    Create a new edition record linked to a specific book.

    This function accepts a Pydantic model containing edition data, links it to
    the provided book ID, converts it into an SQLAlchemy model, and persists it.

    Args:
        book_id (str): The unique identifier of the book this edition belongs to.
        body (books_schemas.EditionPydantic): The validated Pydantic model containing
            the edition data.
        db (Session): The active SQLAlchemy database session. Defaults to `get_db`.

    Returns:
        dict: A dictionary containing the created SQLAlchemy edition object, a success
        message, and the newly generated edition ID.
    """
    #transforma o body que está em um obj pydantic em um modelo do SQLAlchemy para persistir no banco
    
    edition  = books_models.Edition(**body.model_dump(exclude={"id", "book_id"}), book_id=book_id)

    db.add(edition)
    db.commit()
    db.refresh(edition)

    return {"data": edition,
            "message": "Edition created successfully",
            "editionId": edition.id}

def create_announcement(user_id: str, body: announcements_schemas.TradeAnnouncementPydantic, db: Session = Depends(get_db)):
    """
    Create a new trade announcement linked to a specific user.

    This function accepts a Pydantic model containing announcement data, links it
    to the provided user ID, converts it into an SQLAlchemy model, and persists it
    to the database.

    Args:
        user_id (str): The unique identifier of the user creating the announcement.
        body (announcements_schemas.TradeAnnouncementPydantic): The validated Pydantic
            model containing the announcement data.
        db (Session): The active SQLAlchemy database session. Defaults to `get_db`.

    Returns:
        dict: A dictionary containing the created SQLAlchemy announcement object and
        a success message.
    """
    #transforma o body que está em um obj pydantic em um modelo do SQLAlchemy para persistir no banco
    body_data = body.model_dump(exclude={"id", "user_id"})
    if body.cep_id:
        loc = locations_services.get_or_create_location_by_cep(body.cep_id, db)
        body_data["cep_id"] = loc.cep
    #transforma o body que est  em um obj pydantic em um modelo do SQLAlchemy para persistir no banco
    announcement = announcements_models.TradeAnnouncement(**body_data, user_id=user_id) #vantagem, se mudarmos o modelo, n o quebra
    db.add(announcement)
    db.commit()
    db.refresh(announcement)
    return {"data": announcement, "message": "Announcement created successfully"}
