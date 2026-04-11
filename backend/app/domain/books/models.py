import uuid
import enum
from sqlalchemy import Enum as SQLAlchemyEnum, Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class Genre(str, enum.Enum):
    Fantasy = "Fantasy"
    Romance = "Romance"
    Sci_fic = "Sci_fic"
    Non_fiction = "Non_fiction"
    Biography = "Biography"
    Graphic_novel = "Graphic_novel"
    Horror = "Horror"
    Self_help = "Self_help"
    Thriller = "Thriller"
    Education = "Education"

class Language(str, enum.Enum):
    PT_br = "PT-br"
    En = "En"
    Espanhol = "Espanhol"

class Book(Base):
    __tablename__ = "books"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String, index=True)
    author = Column(String, index=True)
    genre = Column(SQLAlchemyEnum(Genre))
    synopsis = Column(String)
    
    editions = relationship("Edition", back_populates="book")

class Edition(Base):
    __tablename__ = "editions"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    book_id = Column(String(36), ForeignKey("books.id"))
    publisher = Column(String)
    publish_year = Column(Integer)
    number_of_pages = Column(Integer)
    language = Column(SQLAlchemyEnum(Language))
    
    book = relationship("Book", back_populates="editions")
    announcements = relationship("TradeAnnouncement", back_populates="edition")

