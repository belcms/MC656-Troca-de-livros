from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware
from app.domain.books import models as books_models
from app.domain.users import models as users_models
from app.domain.announcements import models as announcements_models
from app.domain.announcements.router import router as announcements_router
from app.core.database import engine, Base, get_db
from app.domain.users.router import router as users_router

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

@app.post("/create-dummy-data")
def create_dummy_data(db: Session = Depends(get_db)):
    user1 = users_models.User(
        username="rafael",
        email="rafael@example.com",
        full_name="Rafael Feltrin",
        cep="12345678"
    )
    user2 = users_models.User(
        username="Neymar",
        email="neymar@example.com",
        full_name="Neymar Jr.",
        cep="87654321"
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
        real_photo_url="https://example.com/photo1.jpg",
        condition=announcements_models.Condition.Good,
        description="Muito muito bom, cuido muito bem",
        status=announcements_models.Status.Available
    )
    announcement2 = announcements_models.TradeAnnouncement(
        user_id=user2.id,
        edition_id=edition2.id,
        real_photo_url="https://example.com/photo2.jpg",
        condition=announcements_models.Condition.New,
        description="Nunca nem abri essa bomba",
        status=announcements_models.Status.Available
    )
    db.add_all([announcement1, announcement2])
    db.commit()
    db.refresh(announcement1)  
    db.refresh(announcement2)

    return {"message": "Dummy data created successfully!",
            "announcement_ids": [announcement1.id, announcement2.id]}


@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: str | None = None):
    return {"item_id": item_id, "q": q}

# @app.get("/users")
# def get_users(db: Session = Depends(get_db)):
#     # Puxa os 5 primeiros usuários do banco para testar
#     users = db.query(users_models.User).limit(5).all()
#     return users