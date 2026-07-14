from pydantic import BaseModel, Field
from typing import Optional

from app.domain.books.models import Genre
from app.domain.books.models import Language


#pydantic models
class BookPydantic(BaseModel):
    id: Optional[str] = None
    title: str
    author: str
    genre: Genre
    synopsis: str

    class Config:
        orm_mode = True


class EditionPydantic(BaseModel):
    id: Optional[str] = None
    book_id: Optional[str] = Field(default=None, alias="bookId")
    publisher: str
    publish_year: int = Field(alias="year")
    number_of_pages: int = Field(alias="pages")
    language: Language
    cover_photo: Optional[str] = None

    class Config:
        from_attributes = True 

class BookUpdatePayload(BaseModel):
    title: Optional[str] = None
    author: Optional[str] = None
    synopsis: Optional[str] = None
    genre: Optional[str] = None
    publisher: Optional[str] = None
    language: Optional[str] = None
    publishYear: Optional[int] = None
    pages: Optional[int] = None
    description: Optional[str] = None
    real_photo_url: Optional[str] = None
    cep_id: Optional[str] = None
    status: Optional[str] = None
    condition: Optional[str] = None