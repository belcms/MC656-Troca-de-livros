from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.domain.books import models as books_models
from app.domain.users import models as users_models
from app.domain.announcements import models as announcements_models
from app.domain.offer import models as offer_models
from app.domain.locations import models as location_model

from app.domain.announcements import models as announcements_models
from app.domain.announcements.services import create_dummy_data
# from app.domain.announcements.router import router as announcements_router
from app.api.v1.announcements.router import router as announcements_router
from app.core.database import engine, Base, get_db, ensure_schema_compatibility
from app.api.v1.users.router import router as users_router
from app.api.v1.books.router import router as books_router
from app.api.v1.auth.router import router as auth_router
from app.api.v1.offer.router import router_offer as offer_router
from app.api.v1.offer.router import router_offer_announcement as offer_announcement_router
from app.api.v1.locations.router import router as locations_router

# books_models.Base.metadata.create_all(bind=engine)
# users_models.Base.metadata.create_all(bind=engine)
# announcements_models.Base.metadata.create_all(bind=engine)
# offer_models.Base.metadata.create_all(bind=engine)

#

# Base.metadata.create_all(bind=engine)


@asynccontextmanager
async def lifespan(app: FastAPI):
    books_models.Base.metadata.create_all(bind=engine)
    users_models.Base.metadata.create_all(bind=engine)
    announcements_models.Base.metadata.create_all(bind=engine)
    offer_models.Base.metadata.create_all(bind=engine)
    location_model.Base.metadata.create_all(bind=engine)

    Base.metadata.create_all(bind=engine)

    yield
    # Tudo que está depois do yield roda quando o servidor desligar

# 2. Passe a função para o app e remova a linha que estava solta no arquivo
app = FastAPI(lifespan=lifespan)


# app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Permite que qualquer frontend conecte localmente
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(announcements_router)
app.include_router(users_router)
app.include_router(books_router)
app.include_router(auth_router)
app.include_router(offer_announcement_router)
app.include_router(offer_router)
app.include_router(locations_router)

@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: str | None = None):
    return {"item_id": item_id, "q": q}

@app.post("/create-dummy-data")
async def create_dummy(db: Session = Depends(get_db)):
    return await create_dummy_data(db)
