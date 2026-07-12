from __future__ import annotations

from typing import Any, Dict, List

import pytest
from sqlalchemy.orm import Session

from app.domain.announcements.models import Condition, Status, TradeAnnouncement
from app.domain.books.models import Book, Edition, Genre, Language
from app.domain.users.models import User


def _seed_search_announcement(
    db_session: Session,
    *,
    username: str,
    email: str,
    full_name: str,
    cep: str,
    title: str,
    author: str,
    publisher: str,
    publish_year: int,
    status: Status = Status.Available,
) -> Dict[str, Any]:
    user = User(
        username=username,
        email=email,
        full_name=full_name,
        cep=cep,
    )
    db_session.add(user)
    db_session.flush()

    book = Book(
        title=title,
        author=author,
        genre=Genre.Fantasy,
        synopsis=f"Sinopse de teste para {title}",
    )
    db_session.add(book)
    db_session.flush()

    edition = Edition(
        book_id=book.id,
        publisher=publisher,
        publish_year=publish_year,
        number_of_pages=320,
        language=Language.PT_br,
    )
    db_session.add(edition)
    db_session.flush()

    announcement = TradeAnnouncement(
        user_id=user.id,
        edition_id=edition.id,
        real_photo_url=f"https://example.com/{title.lower().replace(' ', '-')}.jpg",
        condition=Condition.Good,
        description=f"Anuncio para {title}",
        status=status,
    )
    db_session.add(announcement)
    db_session.flush()

    return {
        "user": user,
        "book": book,
        "edition": edition,
        "announcement": announcement,
    }


@pytest.fixture
def search_catalog(db_session: Session) -> Dict[str, Any]:
    records: List[Dict[str, Any]] = []

    dataset = [
        {
            "username": "tolkien_1",
            "email": "tolkien_1@example.com",
            "full_name": "J. R. R. Tolkien",
            "cep": "13001001",
            "title": "Senhor dos Anéis",
            "author": "J. R. R. Tolkien",
            "publisher": "HarperCollins",
            "publish_year": 1954,
        },
        {
            "username": "tolkien_2",
            "email": "tolkien_2@example.com",
            "full_name": "John Tolkien",
            "cep": "13001002",
            "title": "O Hobbit",
            "author": "J. R. R. Tolkien",
            "publisher": "HarperCollins",
            "publish_year": 1937,
        },
        {
            "username": "rowling_1",
            "email": "rowling_1@example.com",
            "full_name": "J. K. Rowling",
            "cep": "13001003",
            "title": "Harry Potter e a Pedra Filosofal",
            "author": "J. K. Rowling",
            "publisher": "Rocco",
            "publish_year": 1997,
        },
        {
            "username": "rowling_2",
            "email": "rowling_2@example.com",
            "full_name": "Joanne Rowling",
            "cep": "13001004",
            "title": "Harry Potter e a Câmara Secreta",
            "author": "J. K. Rowling",
            "publisher": "Rocco",
            "publish_year": 1998,
        },
        {
            "username": "keyes_1",
            "email": "keyes_1@example.com",
            "full_name": "Daniel Keyes",
            "cep": "13001005",
            "title": "Flores para Algernon",
            "author": "Daniel Keyes",
            "publisher": "Civilização Brasileira",
            "publish_year": 1966,
        },
        {
            "username": "amado_1",
            "email": "amado_1@example.com",
            "full_name": "Jorge Amado",
            "cep": "13001006",
            "title": "Capitães da Areia",
            "author": "Jorge Amado",
            "publisher": "Record",
            "publish_year": 1937,
        },
        {
            "username": "garcia_1",
            "email": "garcia_1@example.com",
            "full_name": "Gabriel García Márquez",
            "cep": "13001007",
            "title": "Cem Anos de Solidão",
            "author": "Gabriel García Márquez",
            "publisher": "Record",
            "publish_year": 1967,
        },
        {
            "username": "orwell_1",
            "email": "orwell_1@example.com",
            "full_name": "George Orwell",
            "cep": "13001008",
            "title": "A Revolução dos Bichos",
            "author": "George Orwell",
            "publisher": "Companhia das Letras",
            "publish_year": 1945,
        },
        {
            "username": "martin_1",
            "email": "martin_1@example.com",
            "full_name": "Robert C. Martin",
            "cep": "13001009",
            "title": "Clean Code",
            "author": "Robert C. Martin",
            "publisher": "Prentice Hall",
            "publish_year": 2008,
        },
        {
            "username": "fowler_1",
            "email": "fowler_1@example.com",
            "full_name": "Martin Fowler",
            "cep": "13001010",
            "title": "Refactoring",
            "author": "Martin Fowler",
            "publisher": "Addison-Wesley",
            "publish_year": 1999,
        },
        {
            "username": "hunt_1",
            "email": "hunt_1@example.com",
            "full_name": "Andrew Hunt",
            "cep": "13001011",
            "title": "The Pragmatic Programmer",
            "author": "Andrew Hunt",
            "publisher": "Addison-Wesley",
            "publish_year": 1999,
        },
        {
            "username": "matthes_1",
            "email": "matthes_1@example.com",
            "full_name": "Eric Matthes",
            "cep": "13001012",
            "title": "Python Crash Course",
            "author": "Eric Matthes",
            "publisher": "No Starch Press",
            "publish_year": 2019,
        },
        {
            "username": "adams_1",
            "email": "adams_1@example.com",
            "full_name": "Douglas Adams",
            "cep": "13001013",
            "title": "O Guia do Mochileiro das Galáxias: O Restaurante no Fim do Universo",
            "author": "Douglas Adams",
            "publisher": "Arqueiro",
            "publish_year": 1980,
        },
        {
            "username": "verne_1",
            "email": "verne_1@example.com",
            "full_name": "Jules Verne",
            "cep": "13001014",
            "title": "Vinte Mil Léguas Submarinas",
            "author": "Jules Verne",
            "publisher": "Companhia Editora Nacional",
            "publish_year": 1870,
        },
        {
            "username": "orwell_2",
            "email": "orwell_2@example.com",
            "full_name": "George Orwell",
            "cep": "13001015",
            "title": "1984",
            "author": "George Orwell",
            "publisher": "Companhia das Letras",
            "publish_year": 1949,
        },
    ]

    for spec in dataset:
        record = _seed_search_announcement(
            db_session,
            username=spec["username"],
            email=spec["email"],
            full_name=spec["full_name"],
            cep=spec["cep"],
            title=spec["title"],
            author=spec["author"],
            publisher=spec["publisher"],
            publish_year=spec["publish_year"],
        )
        records.append(record)

    db_session.commit()

    return {
        "records": records,
        "by_title": {record["book"].title: record for record in records},
        "by_author": {
            "J. R. R. Tolkien": [records[0], records[1]],
            "J. K. Rowling": [records[2], records[3]],
            "Daniel Keyes": [records[4]],
            "Jorge Amado": [records[5]],
            "Gabriel García Márquez": [records[6]],
            "George Orwell": [records[7], records[14]],
            "Robert C. Martin": [records[8]],
            "Martin Fowler": [records[9]],
            "Andrew Hunt": [records[10]],
            "Eric Matthes": [records[11]],
            "Douglas Adams": [records[12]],
            "Jules Verne": [records[13]],
        },
        "by_publisher": {
            "HarperCollins": [records[0], records[1]],
            "Rocco": [records[2], records[3]],
            "Addison-Wesley": [records[9], records[10]],
            "Record": [records[5], records[6]],
        },
        "by_year": {
            1999: [records[9], records[10]],
            1937: [records[1], records[5]],
        },
    }