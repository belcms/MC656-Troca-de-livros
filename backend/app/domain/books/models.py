import enum
from sqlalchemy import Enum, Column, Integer, String
from app.core.database import Base

class Genre(str, enum.Enum):
    FICTION = "Fiction"
    NON_FICTION = "Non-Fiction"
    FANTASY = "Fantasy"
    SCIENCE_FICTION = "Science Fiction"
    MYSTERY = "Mystery"
    BIOGRAPHY = "Biography"
    
class Book(Base):
    __tablename__ = "books"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    author = Column(String, index=True)
    genre = Column(Enum(Genre))
    synopsis = Column(String, index=True)

