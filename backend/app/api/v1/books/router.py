from fastapi import APIRouter, Body, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db

import app.domain.books.schemas as books_schemas
from app.domain.announcements import services as books_services

router = APIRouter(prefix='/api/v1', tags=['books'])

@router.put("/books/{id}")
def update_book(id: str,body: dict = Body(...),db: Session = Depends(get_db),):
    """Update an existing book's information.

    The endpoint delegates to the books service to update the properties
    of a specific book using the provided dictionary payload.

    Args:
        id: Book identifier from path parameters.
        body: A dictionary containing the fields to update.
        db: SQLAlchemy session injected by FastAPI.

    Returns:
        The updated book payload.
    """
    return books_services.update_book(id, body, db)

@router.get("/books/details/{id}")
def get_book_details(id: str, db: Session = Depends(get_db)):
    """Retrieve detailed information for a specific book.

    The endpoint delegates to the books service to fetch the full details
    associated with the given book ID.

    Args:
        id: Book identifier from path parameters.
        db: SQLAlchemy session injected by FastAPI.

    Returns:
        The detailed book payload.
    """
    return books_services.get_announcement_details(db, id)

@router.post("/books", status_code=201)
def create_book(body: books_schemas.BookPydantic, db: Session = Depends(get_db)):
    """Create a new book entry.

    The endpoint delegates to the books service to persist a new book
    record based on the provided schema.

    Args:
        body: The payload containing the new book details.
        db: SQLAlchemy session injected by FastAPI.

    Returns:
        The created book payload with HTTP 201 status.
    """
    return books_services.create_book(body, db)

@router.post("/editions/{book_id}", status_code=201)
def create_edition(book_id: str, body: books_schemas.EditionPydantic, db: Session = Depends(get_db)):
    """Create a new edition for a specific book.

    The endpoint delegates to the books service to persist a new edition
    record associated with the given book ID.

    Args:
        book_id: Book identifier from path parameters.
        body: The payload containing the new edition details.
        db: SQLAlchemy session injected by FastAPI.

    Returns:
        The created edition payload with HTTP 201 status.
    """
    return books_services.create_edition(book_id, body, db)