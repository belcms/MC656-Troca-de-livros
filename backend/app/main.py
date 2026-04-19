from fastapi import FastAPI, Depends, Body, HTTPException
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware

from app.domain.books import models as books_models
from app.domain.users import models as users_models
from app.domain.announcements import models as announcements_models
# from app.domain.announcements.router import router as announcements_router
from app.api.v1.announcements.router import router as announcements_router
from app.core.database import engine, Base, get_db
from app.api.v1.users.router import router as users_router

books_models.Base.metadata.create_all(bind=engine)
users_models.Base.metadata.create_all(bind=engine)
announcements_models.Base.metadata.create_all(bind=engine)

Base.metadata.create_all(bind=engine)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Permite que qualquer frontend conecte localmente
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(announcements_router)
app.include_router(users_router)


def map_genre(value: str):
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
    mapping = {
        "PT-br": books_models.Language.PT_br,
        "En": books_models.Language.En,
        "Espanhol": books_models.Language.Espanhol,
    }
    return mapping.get(value, books_models.Language.PT_br)


def map_status(value: str):
    mapping = {
        "Available": announcements_models.Status.Available,
        "Reserved": announcements_models.Status.Reserved,
        "Traded": announcements_models.Status.Traded,
    }
    return mapping.get(value, announcements_models.Status.Available)


def map_condition(value: str):
    mapping = {
        "New": announcements_models.Condition.New,
        "Good": announcements_models.Condition.Good,
        "Used": announcements_models.Condition.Used,
        "Worn": announcements_models.Condition.Worn,
    }
    return mapping.get(value, announcements_models.Condition.New)


@app.post("/create-dummy-data")
def create_dummy_data(db: Session = Depends(get_db)):
    existing = db.query(announcements_models.TradeAnnouncement).first()

    if existing:
        announcements = db.query(announcements_models.TradeAnnouncement).all()
        return {
            "message": "Dummy data already exists!",
            "announcement_ids": [a.id for a in announcements]
        }

    user1 = users_models.User(
        username="rafael",
        email="rafael@example.com",
        full_name="Rafael Feltrin",
        cep="Hortolândia - SP" #Just for now while we don't integrate with a Sedex API
    )
    user2 = users_models.User(
        username="Neymar",
        email="neymar@example.com",
        full_name="Neymar Jr.",
        cep="Santos - SP" #Just for now while we don't integrate with a Sedex API
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
        real_photo_url="https://m.media-amazon.com/images/I/91g5gcjTxsL._SY522_.jpg",
        condition=announcements_models.Condition.Good,
        description="Muito muito bom, cuido muito bem",
        status=announcements_models.Status.Available
    )
    announcement2 = announcements_models.TradeAnnouncement(
        user_id=user2.id,
        edition_id=edition2.id,
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


@app.get("/api/v1/books/details/{id}")
def get_book_details(id: str, db: Session = Depends(get_db)):
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


@app.put("/api/v1/books/{id}")
def update_book(
    id: str,
    body: dict = Body(...),
    db: Session = Depends(get_db),
):
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
    announcement.status = map_status(body.get("status", announcement.status.value))
    announcement.condition = map_condition(body.get("condition", announcement.condition.value))

    db.commit()

    return {"message": "Book updated successfully"}

@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: str | None = None):
    return {"item_id": item_id, "q": q}
