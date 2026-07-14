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

    class Config:
        from_attributes = True 