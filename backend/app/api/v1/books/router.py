from fastapi import APIRouter, Body, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db

import app.domain.books.schemas as books_schemas
from app.domain.announcements import services as books_services

router = APIRouter(prefix='/api/v1', tags=['books'])

@router.put("/books/{id}")
def update_book(id: str,body: dict = Body(...),db: Session = Depends(get_db),):
    
    return books_services.update_book(id, body, db)

@router.get("/books/details/{id}")
def get_book_details(id: str, db: Session = Depends(get_db)):
    # Assumindo que este seja o nome correto no seu service de books
    return books_services.get_announcement_details(db, id)

@router.post("/books", status_code=201)
def create_book(body: books_schemas.BookPydantic, db: Session = Depends(get_db)):
    return books_services.create_book(body, db)

@router.post("/editions/{book_id}", status_code=201)
def create_edition(book_id: str, body: books_schemas.EditionPydantic, db: Session = Depends(get_db)):
    return books_services.create_edition(book_id, body, db)