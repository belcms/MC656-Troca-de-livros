from fastapi import FastAPI
from app.domain.books import models as books_models
from app.domain.users import models as users_models
from app.core.database import engine, Base

books_models.Base.metadata.create_all(bind=engine)
users_models.Base.metadata.create_all(bind=engine)

Base.metadata.create_all(bind=engine)

app = FastAPI()


@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: str | None = None):
    return {"item_id": item_id, "q": q}