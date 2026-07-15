from fastapi import HTTPException, status
from fastapi.params import Body, Depends
from sqlalchemy.orm import Session, joinedload

import math

from app.api.v1.announcements.schemas import FeedAnnouncementResponse
from app.core.database import get_db
from app.domain.announcements import models
from app.domain.announcements.models import Status
from app.domain.books.models import Edition, Book
from app.domain.users.models import User

from app.domain.books import models as books_models
from app.domain.announcements import models as announcements_models
from app.domain.users import models as users_models

import app.domain.books.schemas as books_schemas
import app.domain.announcements.schemas as announcements_schemas
import app.domain.locations.services as locations_services


def get_announcement_details(db: Session, id: str):
    """
    Retrieve complete details of a trade announcement by its ID.
    """

    announcements = (
        db.query(models.TradeAnnouncement)
        .options(
            joinedload(models.TradeAnnouncement.edition).joinedload(Edition.book),
            joinedload(models.TradeAnnouncement.user),
            joinedload(models.TradeAnnouncement.photos)
        )
        .filter(models.TradeAnnouncement.id == id)
        .first()
    )

    if not announcements:
        raise HTTPException(
            status_code=404,
            detail="Announcement not found",
        )

    edition = announcements.edition

    if not edition:
        raise HTTPException(
            status_code=404,
            detail="Edition information is missing for this announcement",
        )

    book = edition.book

    if not book:
        raise HTTPException(
            status_code=404,
            detail="Book information is missing for this edition",
        )

    user = announcements.user

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User information is missing",
        )

    return _map_announcement_to_dict(announcements, edition, book, user)

def _map_announcement_to_dict(announcements, edition, book, user):
    return {
        "id": announcements.id,
        "user_id": announcements.user_id,
        "user_name": user.username,
        "cep_id": getattr(announcements, "cep_id", None),
        "edition_id": announcements.edition_id,
        "real_photo_url": announcements.real_photo_url,
        "photos": [p.photo_url for p in announcements.photos] if announcements.photos else [],
        "condition": announcements.condition.value,
        "description": announcements.description,
        "create_date": announcements.create_date.isoformat(),
        "status": announcements.status.value,
        "edition": {
            "id": edition.id,
            "book_id": edition.book_id,
            "publisher": edition.publisher,
            "publish_year": edition.publish_year,
            "pages": edition.number_of_pages,
        },
        "book": {
            "id": book.id,
            "title": book.title,
            "author": book.author,
            "synopsis": book.synopsis,
        },
    }

def _has_coordinates(location) -> bool:
    return (
        location is not None
        and getattr(location, "lat", None) is not None
        and getattr(location, "long", None) is not None
    )

def _get_announcement_location(announcement):
    announcement_location = getattr(
        announcement,
        "location",
        None,
    )

    if _has_coordinates(announcement_location):
        return announcement_location

    if (
        getattr(announcement, "user", None) is not None
        and _has_coordinates(
            getattr(announcement.user, "location", None)
        )
    ):
        return announcement.user.location

    return announcement_location

def _build_location_label(announcement):
    location = getattr(
        announcement,
        "location",
        None,
    )

    if location is None and getattr(announcement, "user", None):
        location = getattr(
            announcement.user,
            "location",
            None,
        )

    if location is not None:
        city = getattr(location, "city", None)
        state = getattr(location, "state", None)

        if city and state:
            return f"{city} - {state}"

        if city:
            return city

        if state:
            return state

    return (
        getattr(announcement, "cep_id", None)
        or getattr(announcement.user, "cep_id", None)
        or getattr(announcement.user, "cep", None)
        or "Localização não informada"
    )

def _build_feed_response(announcement, distance_km: float | None = None):
    first_photo_url = ""
    if announcement.photos and len(announcement.photos) > 0:
        first_photo_url = announcement.photos[0].photo_url
    elif announcement.real_photo_url:
        first_photo_url = announcement.real_photo_url

    return FeedAnnouncementResponse(
        id=announcement.id,
        title=announcement.edition.book.title,
        condition=announcement.condition,
        real_photo_url=announcement.real_photo_url,
        cover_photo=first_photo_url, # Passamos só a string aqui!
        publishYear=announcement.edition.publish_year,
        cep=_build_location_label(announcement),
        distanceKm=(
            round(distance_km, 1)
            if distance_km is not None
            else None
        ),
    )


def _calculate_distance_km(
    origin_location,
    target_location,
) -> float:
    earth_radius_km = 6371.0

    origin_lat = math.radians(float(origin_location.lat))
    origin_long = math.radians(float(origin_location.long))
    target_lat = math.radians(float(target_location.lat))
    target_long = math.radians(float(target_location.long))

    delta_lat = target_lat - origin_lat
    delta_long = target_long - origin_long

    haversine_value = (
        math.sin(delta_lat / 2) ** 2
        + math.cos(origin_lat)
        * math.cos(target_lat)
        * math.sin(delta_long / 2) ** 2
    )

    angular_distance = 2 * math.atan2(
        math.sqrt(haversine_value),
        math.sqrt(1 - haversine_value),
    )

    return earth_radius_km * angular_distance



def _build_feed_base_query(db, current_user_id, conditions, genres, start_year, end_year):
    base_query = (
        db.query(models.TradeAnnouncement)
        .join(Edition, models.TradeAnnouncement.edition_id == Edition.id)
        .join(Book, Edition.book_id == Book.id)
        .options(
            joinedload(models.TradeAnnouncement.edition).joinedload(Edition.book),
            joinedload(models.TradeAnnouncement.user).joinedload(User.location),
            joinedload(models.TradeAnnouncement.location),
            joinedload(models.TradeAnnouncement.photos)
        )
        .filter(models.TradeAnnouncement.status == Status.Available)
    )

    if current_user_id:
        base_query = base_query.filter(models.TradeAnnouncement.user_id != current_user_id)

    if conditions:
        mapped_conditions = [map_condition(condition) for condition in conditions]
        base_query = base_query.filter(models.TradeAnnouncement.condition.in_(mapped_conditions))

    if genres:
        mapped_genres = [map_genre(genre) for genre in genres]
        base_query = base_query.filter(Book.genre.in_(mapped_genres))

    if start_year is not None:
        base_query = base_query.filter(Edition.publish_year >= start_year)

    if end_year is not None:
        base_query = base_query.filter(Edition.publish_year <= end_year)

    return base_query

def _process_distance_and_paginate(
    announcements, user_location, distance_filter_enabled, max_distance_km, distance_sort_enabled, offset, limit
):
    announcements_with_distance = []
    for announcement in announcements:
        announcement_location = _get_announcement_location(announcement)
        distance_km = None

        if _has_coordinates(announcement_location):
            distance_km = _calculate_distance_km(
                origin_location=user_location,
                target_location=announcement_location,
            )

        if distance_filter_enabled:
            if distance_km is None or distance_km > max_distance_km:
                continue

        announcements_with_distance.append({
            "announcement": announcement,
            "distance_km": distance_km,
        })

    if distance_sort_enabled:
        announcements_with_distance.sort(
            key=lambda item: (
                item["distance_km"] is None,
                item["distance_km"] if item["distance_km"] is not None else float("inf"),
                -item["announcement"].create_date.timestamp() if item["announcement"].create_date is not None else 0,
            )
        )
    else:
        announcements_with_distance.sort(
            key=lambda item: (
                -item["announcement"].create_date.timestamp() if item["announcement"].create_date is not None else 0,
            )
        )

    return announcements_with_distance[offset : offset + limit]

def get_feed_announcements(
    db: Session,
    limit: int = 20,
    offset: int = 0,
    start_year: int | None = None,
    end_year: int | None = None,
    conditions: list[str] | None = None,
    genres: list[str] | None = None,
    current_user_id: str | None = None,
    sort_by_distance: bool = False,
    max_distance_km: float | None = None,
):
    """
    Retrieves a paginated list of available trade announcements for the feed.
    """

    distance_filter_enabled = max_distance_km is not None
    distance_sort_enabled = sort_by_distance is True

    if distance_filter_enabled and max_distance_km <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="max_distance_km deve ser maior que zero.",
        )

    if distance_filter_enabled and not current_user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Filtro de distância requer current_user_id.",
        )

    base_query = _build_feed_base_query(
        db, current_user_id, conditions, genres, start_year, end_year
    )

    needs_distance_calculation = distance_sort_enabled or distance_filter_enabled

    if not needs_distance_calculation:
        announcements = (
            base_query.order_by(models.TradeAnnouncement.create_date.desc())
            .limit(limit)
            .offset(offset)
            .all()
        )
        return [_build_feed_response(ann) for ann in announcements]

    current_user = (
        db.query(User)
        .options(joinedload(User.location))
        .filter(User.id == current_user_id)
        .first()
    )

    if current_user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuário não encontrado.",
        )

    user_location = getattr(current_user, "location", None)

    if not _has_coordinates(user_location):
        if distance_filter_enabled:
            return []

        announcements = (
            base_query.order_by(models.TradeAnnouncement.create_date.desc())
            .limit(limit)
            .offset(offset)
            .all()
        )
        return [_build_feed_response(ann) for ann in announcements]

    announcements = base_query.all()

    paginated_items = _process_distance_and_paginate(
        announcements, user_location, distance_filter_enabled, max_distance_km, distance_sort_enabled, offset, limit
    )

    return [
        _build_feed_response(
            announcement=item["announcement"],
            distance_km=item["distance_km"],
        )
        for item in paginated_items
    ]

def map_genre(value: str):
    """
    Map a string value to the corresponding Genre enum.
    """

    mapping = {
        "Fantasy": books_models.Genre.Fantasy,
        "Romance": books_models.Genre.Romance,
        "Sci_fic": books_models.Genre.Sci_fic,
        "Non_fiction": books_models.Genre.Non_fiction,
        "Biography": books_models.Genre.Biography,
        "Graphic_novel": books_models.Genre.Graphic_novel,
        "Horror": books_models.Genre.Horror,
        "Self_help": books_models.Genre.Self_help,
        "Thriller": books_models.Genre.Thriller,
        "Education": books_models.Genre.Education,
    }

    return mapping.get(value, books_models.Genre.Romance)


def map_language(value: str):
    """
    Map a string value to the corresponding Language enum.
    """

    mapping = {
        "PT-br": books_models.Language.PT_br,
        "En": books_models.Language.En,
        "Espanhol": books_models.Language.Espanhol,
    }

    return mapping.get(value, books_models.Language.PT_br)


def map_status(value: str):
    """
    Map a string value to the corresponding Status enum.
    """

    mapping = {
        "Available": announcements_models.Status.Available,
        "Reserved": announcements_models.Status.Reserved,
        "Traded": announcements_models.Status.Traded,
    }

    return mapping.get(
        value,
        announcements_models.Status.Available,
    )


def map_condition(value: str):
    """
    Map a string value to the corresponding Condition enum.
    """

    mapping = {
        "New": announcements_models.Condition.New,
        "Good": announcements_models.Condition.Good,
        "Used": announcements_models.Condition.Used,
        "Worn": announcements_models.Condition.Worn,
    }

    return mapping.get(
        value,
        announcements_models.Condition.New,
    )


async def create_dummy_data(db: Session = Depends(get_db)):
    """
    Populate the database with comprehensive dummy data for demonstration.

    Creates a fully populated scenario with:
    - 5 locations across Brazilian cities (varying distances)
    - 5 users, each in a different city
    - 10 books with real Amazon cover images
    - 10 editions (one per book)
    - 15 announcements (3 per user) with varied conditions/statuses
    - Photo records for announcements
    - Wishlist entries for cross-user interest
    - Example trade offers between users
    """
    from datetime import timedelta
    from app.domain.locations import models as locations_models
    from app.domain.offer.models import Offer, OfferedAnnouncements, StatusOffer

    existing = db.query(
        announcements_models.TradeAnnouncement
    ).first()

    if existing:
        announcements = db.query(
            announcements_models.TradeAnnouncement
        ).all()

        return {
            "message": "Dummy data already exists!",
            "announcement_ids": [
                announcement.id
                for announcement in announcements
            ],
        }

    # ──────────────────────────────────────────────────────────
    # 1. LOCATIONS — 5 cidades brasileiras com coordenadas reais
    #    Distâncias aproximadas a partir de Campinas:
    #    - São Paulo:       ~90 km
    #    - Rio de Janeiro:  ~500 km
    #    - Belo Horizonte:  ~580 km
    #    - Curitiba:        ~530 km
    # ──────────────────────────────────────────────────────────
    locations = [
        locations_models.Location(
            cep="13083970",
            city="Campinas",
            state="SP",
            country="Brasil",
            district="Cidade Universitária",
            lat=-22.8179,
            long=-47.0695,
        ),
        locations_models.Location(
            cep="01310200",
            city="São Paulo",
            state="SP",
            country="Brasil",
            district="Bela Vista",
            lat=-23.5614,
            long=-46.6559,
        ),
        locations_models.Location(
            cep="22070002",
            city="Rio de Janeiro",
            state="RJ",
            country="Brasil",
            district="Copacabana",
            lat=-22.9711,
            long=-43.1822,
        ),
        locations_models.Location(
            cep="30140010",
            city="Belo Horizonte",
            state="MG",
            country="Brasil",
            district="Savassi",
            lat=-19.9320,
            long=-43.9378,
        ),
        locations_models.Location(
            cep="80060000",
            city="Curitiba",
            state="PR",
            country="Brasil",
            district="Centro",
            lat=-25.4284,
            long=-49.2671,
        ),
    ]

    db.add_all(locations)
    db.commit()

    # ──────────────────────────────────────────────────────────
    # 2. USERS — 5 usuários, um por cidade
    # ──────────────────────────────────────────────────────────
    user1 = users_models.User(
        username="ana_campinas",
        email="ana.campinas@example.com",
        full_name="Ana Beatriz Souza",
        cep_id="13083970",
    )
    user2 = users_models.User(
        username="bruno_sp",
        email="bruno.sp@example.com",
        full_name="Bruno Oliveira",
        cep_id="01310200",
    )
    user3 = users_models.User(
        username="carla_rio",
        email="carla.rio@example.com",
        full_name="Carla Mendes",
        cep_id="22070002",
    )
    user4 = users_models.User(
        username="diego_bh",
        email="diego.bh@example.com",
        full_name="Diego Ferreira",
        cep_id="30140010",
    )
    user5 = users_models.User(
        username="eva_curitiba",
        email="eva.curitiba@example.com",
        full_name="Eva Santos",
        cep_id="80060000",
    )

    all_users = [user1, user2, user3, user4, user5]
    db.add_all(all_users)
    db.commit()
    for u in all_users:
        db.refresh(u)

    # ──────────────────────────────────────────────────────────
    # 3. BOOKS + EDITIONS — 10 livros reais com capas da Amazon
    #
    #    As URLs de cover_photo foram verificadas e retornam
    #    imagens válidas renderizáveis no app.
    # ──────────────────────────────────────────────────────────
    books_data = [
        {
            "title": "1984",
            "author": "George Orwell",
            "genre": books_models.Genre.Sci_fic,
            "synopsis": "Romance distópico que retrata um regime totalitário onde o Grande Irmão controla todos os aspectos da vida. Winston Smith luta para manter sua individualidade em um mundo de vigilância constante e manipulação da verdade.",
            "publisher": "Companhia das Letras",
            "year": 2009,
            "pages": 416,
            "language": books_models.Language.PT_br,
            "cover": "https://m.media-amazon.com/images/I/91g5gcjTxsL._SY522_.jpg",
        },
        {
            "title": "Dune",
            "author": "Frank Herbert",
            "genre": books_models.Genre.Sci_fic,
            "synopsis": "Uma jornada épica de ficção científica ambientada no deserto de Arrakis, onde política, ecologia, religião e poder se entrelaçam. Paul Atreides precisa sobreviver à traição e liderar uma revolução para cumprir seu destino.",
            "publisher": "Aleph",
            "year": 2017,
            "pages": 680,
            "language": books_models.Language.PT_br,
            "cover": "https://m.media-amazon.com/images/I/81zN7udGRUL._SL1500_.jpg",
        },
        {
            "title": "Dom Casmurro",
            "author": "Machado de Assis",
            "genre": books_models.Genre.Romance,
            "synopsis": "Um dos maiores clássicos da literatura brasileira. Bentinho narra sua história com Capitu, uma relação marcada por ciúme, dúvida e ambiguidade. O leitor deve julgar se houve ou não traição.",
            "publisher": "Penguin-Companhia",
            "year": 2016,
            "pages": 256,
            "language": books_models.Language.PT_br,
            "cover": "https://m.media-amazon.com/images/I/81gepf1eMqL._SY522_.jpg",
        },
        {
            "title": "O Pequeno Príncipe",
            "author": "Antoine de Saint-Exupéry",
            "genre": books_models.Genre.Romance,
            "synopsis": "Fábula poética sobre um príncipe que viaja de planeta em planeta, encontrando personagens que representam aspectos da natureza humana. Uma reflexão atemporal sobre amizade, amor e o que realmente importa na vida.",
            "publisher": "HarperCollins",
            "year": 2018,
            "pages": 96,
            "language": books_models.Language.PT_br,
            "cover": "https://m.media-amazon.com/images/I/81OthjkJBuL._SY522_.jpg",
        },
        {
            "title": "Harry Potter e a Pedra Filosofal",
            "author": "J.K. Rowling",
            "genre": books_models.Genre.Fantasy,
            "synopsis": "Harry Potter descobre que é um bruxo no dia do seu aniversário de 11 anos e é convidado para estudar na Escola de Magia e Bruxaria de Hogwarts. Lá, ele encontra amigos, mistérios e perigos que mudarão sua vida para sempre.",
            "publisher": "Rocco",
            "year": 2017,
            "pages": 208,
            "language": books_models.Language.PT_br,
            "cover": "https://m.media-amazon.com/images/I/91VokXkn8hL._SY522_.jpg",
        },
        {
            "title": "O Senhor dos Anéis: A Sociedade do Anel",
            "author": "J.R.R. Tolkien",
            "genre": books_models.Genre.Fantasy,
            "synopsis": "O hobbit Frodo Bolseiro herda o Um Anel e parte em uma jornada épica pela Terra-média para destruí-lo. A Sociedade do Anel é formada para protegê-lo nesta missão que decidirá o destino de todos os povos livres.",
            "publisher": "HarperCollins",
            "year": 2019,
            "pages": 576,
            "language": books_models.Language.PT_br,
            "cover": "https://m.media-amazon.com/images/I/91ocU8970hL._SY522_.jpg",
        },
        {
            "title": "Grande Sertão: Veredas",
            "author": "João Guimarães Rosa",
            "genre": books_models.Genre.Romance,
            "synopsis": "O ex-jagunço Riobaldo relembra seus amores, suas lutas e o pacto que talvez tenha feito com o diabo, em uma narrativa magistral sobre a alma humana e o sertão brasileiro.",
            "publisher": "Nova Fronteira",
            "year": 2001,
            "pages": 624,
            "language": books_models.Language.PT_br,
            "cover": "https://m.media-amazon.com/images/I/51b5YG6Y1rL._SY445_SX342_.jpg",
        },
        {
            "title": "A Revolução dos Bichos",
            "author": "George Orwell",
            "genre": books_models.Genre.Sci_fic,
            "synopsis": "Fábula satírica onde os animais de uma fazenda se rebelam contra o fazendeiro humano e tomam o controle. Porém, os porcos gradualmente se tornam tão tirânicos quanto os humanos que substituíram.",
            "publisher": "Companhia das Letras",
            "year": 2007,
            "pages": 152,
            "language": books_models.Language.PT_br,
            "cover": "https://m.media-amazon.com/images/I/61R1s5S-h4L._SY522_.jpg",
        },
        {
            "title": "O Hobbit",
            "author": "J.R.R. Tolkien",
            "genre": books_models.Genre.Fantasy,
            "synopsis": "Bilbo Bolseiro, um hobbit pacato, é inesperadamente recrutado pelo mago Gandalf para uma aventura com treze anões. Juntos, partem para recuperar o tesouro guardado pelo dragão Smaug na Montanha Solitária.",
            "publisher": "HarperCollins",
            "year": 2019,
            "pages": 336,
            "language": books_models.Language.PT_br,
            "cover": "https://m.media-amazon.com/images/I/81xL1P-QZGL._SY522_.jpg",
        },
        {
            "title": "Clean Code",
            "author": "Robert C. Martin",
            "genre": books_models.Genre.Education,
            "synopsis": "Guia essencial sobre boas práticas de programação. Ensina como escrever código limpo, legível e manutenível. Aborda nomes significativos, funções pequenas, formatação consistente e a arte de refatorar.",
            "publisher": "Alta Books",
            "year": 2011,
            "pages": 456,
            "language": books_models.Language.PT_br,
            "cover": "https://m.media-amazon.com/images/I/71T7aUQnbfL._SY522_.jpg",
        },
    ]

    all_books = []
    all_editions = []

    for bd in books_data:
        book = books_models.Book(
            title=bd["title"],
            author=bd["author"],
            genre=bd["genre"],
            synopsis=bd["synopsis"],
        )
        db.add(book)
        db.flush()

        edition = books_models.Edition(
            book_id=book.id,
            publisher=bd["publisher"],
            publish_year=bd["year"],
            number_of_pages=bd["pages"],
            language=bd["language"],
            cover_photo=bd["cover"],
        )
        db.add(edition)
        db.flush()

        all_books.append(book)
        all_editions.append(edition)

    db.commit()
    for b in all_books:
        db.refresh(b)
    for e in all_editions:
        db.refresh(e)

    # ──────────────────────────────────────────────────────────
    # 4. ANNOUNCEMENTS — 15 no total, 3 por usuário
    #
    #    Cada anúncio usa a cover_photo da edition como
    #    real_photo_url, simulando fotos reais do livro.
    # ──────────────────────────────────────────────────────────
    from datetime import datetime

    announcements_data = [
        # --- Ana (Campinas) - 3 anúncios ---
        {
            "user": user1,
            "edition": all_editions[0],  # 1984
            "cep_id": "13083970",
            "condition": announcements_models.Condition.Good,
            "description": "Exemplar bem conservado, com poucas marcas de leitura. Capa em ótimo estado.",
            "status": announcements_models.Status.Available,
            "days_ago": 2,
        },
        {
            "user": user1,
            "edition": all_editions[2],  # Dom Casmurro
            "cep_id": "13083970",
            "condition": announcements_models.Condition.Used,
            "description": "Livro usado mas legível. Algumas anotações a lápis nas margens. Clássico que todo mundo deveria ler!",
            "status": announcements_models.Status.Available,
            "days_ago": 5,
        },
        {
            "user": user1,
            "edition": all_editions[3],  # O Pequeno Príncipe
            "cep_id": "13083970",
            "condition": announcements_models.Condition.New,
            "description": "Edição nova, nunca foi lida. Presente que ganhei em duplicata. Capa dura linda!",
            "status": announcements_models.Status.Available,
            "days_ago": 1,
        },
        # --- Bruno (São Paulo) - 3 anúncios ---
        {
            "user": user2,
            "edition": all_editions[1],  # Dune
            "cep_id": "01310200",
            "condition": announcements_models.Condition.Good,
            "description": "Edição em ótimo estado. Lombada sem vincos, páginas limpas. Imperdível para fãs de ficção científica!",
            "status": announcements_models.Status.Available,
            "days_ago": 3,
        },
        {
            "user": user2,
            "edition": all_editions[4],  # Harry Potter
            "cep_id": "01310200",
            "condition": announcements_models.Condition.Good,
            "description": "Meu exemplar de infância. Muito bem cuidado, com capa protetora. Magia pura!",
            "status": announcements_models.Status.Available,
            "days_ago": 7,
        },
        {
            "user": user2,
            "edition": all_editions[9],  # Clean Code
            "cep_id": "01310200",
            "condition": announcements_models.Condition.New,
            "description": "Comprei para um curso e já tenho a versão digital. Livro novo, sem uso.",
            "status": announcements_models.Status.Available,
            "days_ago": 4,
        },
        # --- Carla (Rio de Janeiro) - 3 anúncios ---
        {
            "user": user3,
            "edition": all_editions[5],  # Senhor dos Anéis
            "cep_id": "22070002",
            "condition": announcements_models.Condition.Good,
            "description": "Edição linda da HarperCollins. Li uma vez e guardei com carinho. Sem marcas!",
            "status": announcements_models.Status.Available,
            "days_ago": 6,
        },
        {
            "user": user3,
            "edition": all_editions[6],  # Grande Sertão
            "cep_id": "22070002",
            "condition": announcements_models.Condition.Used,
            "description": "Livro que viajou comigo pelo Brasil. Tem marcas de uso, mas está inteiro e legível.",
            "status": announcements_models.Status.Available,
            "days_ago": 10,
        },
        {
            "user": user3,
            "edition": all_editions[7],  # Revolução dos Bichos
            "cep_id": "22070002",
            "condition": announcements_models.Condition.Good,
            "description": "Acabei de terminar e quero trocar por algo novo. Muito bom estado!",
            "status": announcements_models.Status.Reserved,
            "days_ago": 8,
        },
        # --- Diego (Belo Horizonte) - 3 anúncios ---
        {
            "user": user4,
            "edition": all_editions[8],  # O Hobbit
            "cep_id": "30140010",
            "condition": announcements_models.Condition.New,
            "description": "Ganhei dois exemplares de aniversário. Este está lacrado, nunca aberto!",
            "status": announcements_models.Status.Available,
            "days_ago": 3,
        },
        {
            "user": user4,
            "edition": all_editions[0],  # 1984 (segunda edição)
            "cep_id": "30140010",
            "condition": announcements_models.Condition.Worn,
            "description": "Edição antiga que já foi lida várias vezes. Capa com desgaste, mas o conteúdo é incrível. Para quem não liga para estética.",
            "status": announcements_models.Status.Available,
            "days_ago": 15,
        },
        {
            "user": user4,
            "edition": all_editions[4],  # Harry Potter (outro exemplar)
            "cep_id": "30140010",
            "condition": announcements_models.Condition.Good,
            "description": "Versão brasileira da Rocco em bom estado. Li e quero passar pra frente!",
            "status": announcements_models.Status.Available,
            "days_ago": 9,
        },
        # --- Eva (Curitiba) - 3 anúncios ---
        {
            "user": user5,
            "edition": all_editions[6],  # Grande Sertão (outro exemplar)
            "cep_id": "80060000",
            "condition": announcements_models.Condition.Good,
            "description": "Leitura transformadora. Exemplar em excelente estado, capa perfeita.",
            "status": announcements_models.Status.Available,
            "days_ago": 4,
        },
        {
            "user": user5,
            "edition": all_editions[1],  # Dune (outro exemplar)
            "cep_id": "80060000",
            "condition": announcements_models.Condition.Used,
            "description": "Li antes de assistir o filme. Está com a lombada um pouco marcada mas tudo legível.",
            "status": announcements_models.Status.Traded,
            "days_ago": 20,
        },
        {
            "user": user5,
            "edition": all_editions[5],  # Senhor dos Anéis (outro exemplar)
            "cep_id": "80060000",
            "condition": announcements_models.Condition.New,
            "description": "Edição especial novinha em folha. Presente de Natal que já tenho. Perfeito para colecionadores!",
            "status": announcements_models.Status.Available,
            "days_ago": 2,
        },
    ]

    all_announcements = []
    for ad in announcements_data:
        announcement = announcements_models.TradeAnnouncement(
            user_id=ad["user"].id,
            edition_id=ad["edition"].id,
            cep_id=ad["cep_id"],
            real_photo_url=ad["edition"].cover_photo,
            condition=ad["condition"],
            description=ad["description"],
            status=ad["status"],
            create_date=datetime.utcnow() - timedelta(days=ad["days_ago"]),
        )
        db.add(announcement)
        db.flush()
        all_announcements.append(announcement)

    db.commit()
    for a in all_announcements:
        db.refresh(a)

    # ──────────────────────────────────────────────────────────
    # 5. PHOTOS — Uma foto por anúncio na tabela PhotoTradeAnnouncement
    #
    #    Usa a mesma URL da cover como foto do post.
    #    Como o frontend renderiza via Image.network(url),
    #    qualquer URL pública de imagem funciona — não precisa
    #    ser do Supabase para o dummy data.
    # ──────────────────────────────────────────────────────────
    all_photos = []
    for ann in all_announcements:
        if ann.real_photo_url:
            photo = announcements_models.PhotoTradeAnnouncement(
                trade_announcement_id=ann.id,
                photo_url=ann.real_photo_url,
            )
            db.add(photo)
            all_photos.append(photo)

    db.commit()

    # ──────────────────────────────────────────────────────────
    # 6. WISHLIST — Interesses cruzados entre usuários
    # ──────────────────────────────────────────────────────────
    wishlist_entries = [
        # Ana quer Dune e Harry Potter
        users_models.Wishlist(user_id=user1.id, edition_id=all_editions[1].id),
        users_models.Wishlist(user_id=user1.id, edition_id=all_editions[4].id),
        # Bruno quer Dom Casmurro e O Hobbit
        users_models.Wishlist(user_id=user2.id, edition_id=all_editions[2].id),
        users_models.Wishlist(user_id=user2.id, edition_id=all_editions[8].id),
        # Carla quer 1984 e Clean Code
        users_models.Wishlist(user_id=user3.id, edition_id=all_editions[0].id),
        users_models.Wishlist(user_id=user3.id, edition_id=all_editions[9].id),
        # Diego quer O Pequeno Príncipe e Senhor dos Anéis
        users_models.Wishlist(user_id=user4.id, edition_id=all_editions[3].id),
        users_models.Wishlist(user_id=user4.id, edition_id=all_editions[5].id),
        # Eva quer Dom Casmurro e A Revolução dos Bichos
        users_models.Wishlist(user_id=user5.id, edition_id=all_editions[2].id),
        users_models.Wishlist(user_id=user5.id, edition_id=all_editions[7].id),
    ]
    db.add_all(wishlist_entries)
    db.commit()

    # ──────────────────────────────────────────────────────────
    # 7. OFFERS — Propostas de troca entre usuários
    #
    #    Cenário:
    #    - Bruno quer o 1984 da Ana, oferecendo seu Dune
    #    - Carla quer o Pequeno Príncipe da Ana, oferecendo O Alquimista
    #    - Diego quer o Harry Potter do Bruno, oferecendo O Hobbit
    # ──────────────────────────────────────────────────────────
    offer1 = Offer(
        user_id=user2.id,
        target_announcement_id=all_announcements[0].id,  # Ana: 1984
        status_offer=StatusOffer.Pending,
    )
    db.add(offer1)
    db.flush()

    db.add(OfferedAnnouncements(
        offer_id=offer1.id,
        offered_announcement_id=all_announcements[3].id,  # Bruno: Dune
    ))

    offer2 = Offer(
        user_id=user3.id,
        target_announcement_id=all_announcements[2].id,  # Ana: Pequeno Príncipe
        status_offer=StatusOffer.Pending,
    )
    db.add(offer2)
    db.flush()

    db.add(OfferedAnnouncements(
        offer_id=offer2.id,
        offered_announcement_id=all_announcements[7].id,  # Carla: Grande Sertão
    ))

    offer3 = Offer(
        user_id=user4.id,
        target_announcement_id=all_announcements[4].id,  # Bruno: Harry Potter
        status_offer=StatusOffer.Pending,
    )
    db.add(offer3)
    db.flush()

    db.add(OfferedAnnouncements(
        offer_id=offer3.id,
        offered_announcement_id=all_announcements[9].id,  # Diego: O Hobbit
    ))

    db.commit()

    return {
        "message": "Dummy data created successfully!",
        "summary": {
            "locations": 5,
            "users": 5,
            "books": 10,
            "editions": 10,
            "announcements": 15,
            "photos": len(all_photos),
            "wishlist_entries": len(wishlist_entries),
            "offers": 3,
        },
        "users": [
            {
                "id": u.id,
                "username": u.username,
                "full_name": u.full_name,
                "city": u.location.city if u.location else None,
            }
            for u in all_users
        ],
        "announcement_ids": [
            announcement.id
            for announcement in all_announcements
        ],
    }


def get_book_details(
    id: str,
    db: Session = Depends(get_db),
):
    """
    Retrieve detailed information about a book from a specific announcement.
    """

    announcement = (
        db.query(announcements_models.TradeAnnouncement)
        .filter(announcements_models.TradeAnnouncement.id == id)
        .first()
    )

    if not announcement:
        raise HTTPException(
            status_code=404,
            detail="Announcement not found",
        )

    edition = announcement.edition
    book = edition.book

    return {
        "id": announcement.id,
        "title": book.title,
        "author": book.author,
        "publisher": edition.publisher,
        "genre": book.genre.value,
        "language": edition.language.value,
        "publishYear": edition.publish_year,
        "pages": edition.number_of_pages,
        "synopsis": book.synopsis,
        "description": announcement.description,
        "status": announcement.status.value,
        "condition": announcement.condition.value,
        "real_photo_url": announcement.real_photo_url,
    }


def update_book(
    id: str,
    payload: books_schemas.BookUpdatePayload,
    db: Session = Depends(get_db),
    owner_id: str | None = None,
):
    """
    Update the details of an existing book, edition, and announcement.
    """

    announcement = (
        db.query(announcements_models.TradeAnnouncement)
        .filter(announcements_models.TradeAnnouncement.id == id)
        .first()
    )

    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")
    if owner_id is not None and announcement.user_id != owner_id:
        raise HTTPException(status_code=403, detail="Acesso negado")

    edition = announcement.edition
    book = edition.book

    if payload.title is not None:
        book.title = payload.title
    if payload.author is not None:
        book.author = payload.author
    if payload.synopsis is not None:
        book.synopsis = payload.synopsis
    if payload.genre is not None:
        book.genre = map_genre(payload.genre)

    if payload.publisher is not None:
        edition.publisher = payload.publisher
    if payload.language is not None:
        edition.language = map_language(payload.language)
    if payload.publishYear is not None:
        edition.publish_year = payload.publishYear
    if payload.pages is not None:
        edition.number_of_pages = payload.pages

    if payload.description is not None:
        announcement.description = payload.description
    if payload.real_photo_url is not None:
        announcement.real_photo_url = payload.real_photo_url
    if payload.status is not None:
        announcement.status = map_status(payload.status)
    if payload.condition is not None:
        announcement.condition = map_condition(payload.condition)

    if payload.cep_id is not None:
        clean_cep = locations_services.normalize_cep(payload.cep_id)
        if clean_cep is None:
            announcement.cep_id = None
        else:
            loc = locations_services.get_or_create_location_by_cep(clean_cep, db)
            announcement.cep_id = loc.cep

    db.commit()

    return {
        "message": "Book updated successfully",
    }

def create_book(
    body: books_schemas.BookPydantic,
    db: Session = Depends(get_db),
):
    """
    Create a new book record in the database.
    """

    book = books_models.Book(
        **body.model_dump(exclude={"id"})
    )

    db.add(book)
    db.commit()
    db.refresh(book)

    return {
        "data": book,
        "message": "Book created successfully",
        "bookId": book.id,
    }


def create_edition(
    book_id: str,
    body: books_schemas.EditionPydantic,
    db: Session = Depends(get_db),
):
    """
    Create a new edition record linked to a specific book.
    """

    edition = books_models.Edition(
        **body.model_dump(exclude={"id", "book_id"}),
        book_id=book_id,
    )

    db.add(edition)
    db.commit()
    db.refresh(edition)

    return {
        "data": edition,
        "message": "Edition created successfully",
        "editionId": edition.id,
    }


def create_announcement(
    user_id: str,
    body: announcements_schemas.TradeAnnouncementPydantic,
    db: Session = Depends(get_db),
):
    """
    Create a new trade announcement linked to a specific user.
    """

    body_data = body.model_dump(
        exclude={"id", "user_id"}
    )

    if body.cep_id:
        loc = locations_services.get_or_create_location_by_cep(
            body.cep_id,
            db,
        )
        body_data["cep_id"] = loc.cep

    announcement = announcements_models.TradeAnnouncement(
        **body_data,
        user_id=user_id,
    )

    db.add(announcement)
    db.commit()
    db.refresh(announcement)
    return {"data": announcement, "message": "Announcement created successfully"}

def get_book_details(id: str, db: Session = Depends(get_db)):
    announcement = (
        db.query(announcements_models.TradeAnnouncement)
        .filter(announcements_models.TradeAnnouncement.id == id)
        .first()
    )

    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")

    edition = announcement.edition
    book = edition.book

    return {
        "id": announcement.id,
        "title": book.title,
        "author": book.author,
        "publisher": edition.publisher,
        "genre": book.genre.value,
        "language": edition.language.value,
        "publishYear": edition.publish_year,
        "pages": edition.number_of_pages,
        "synopsis": book.synopsis,
        "description": announcement.description,
        "status": announcement.status.value,
        "condition": announcement.condition.value,
        "real_photo_url": announcement.real_photo_url,
    }

def get_edition_details(id: str, db: Session = Depends(get_db)):
    """
    Retrieve detailed information about a specific edition and its book.

    Args:
        id (str): The unique identifier of the edition.
        db (Session): The active SQLAlchemy database session.

    Returns:
        dict: A dictionary containing the edition and book details.

    Raises:
        HTTPException (404): If no edition is found.
    """
    edition = db.query(books_models.Edition).filter(books_models.Edition.id == id).first()
    if not edition:
        raise HTTPException(status_code=404, detail="Edition not found")
        
    book = edition.book
    return {
        "id": edition.id,
        "book_id": book.id,
        "title": book.title,
        "author": book.author,
        "publisher": edition.publisher,
        "genre": book.genre.value if book.genre else None,
        "language": edition.language.value if edition.language else None,
        "publishYear": edition.publish_year,
        "pages": edition.number_of_pages,
        "synopsis": book.synopsis,
        "cover_photo": edition.cover_photo
    }

