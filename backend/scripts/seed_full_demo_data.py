from __future__ import annotations

import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

from sqlalchemy import text

# Permite executar este script a partir da pasta backend:
# python scripts/seed_full_demo_data.py
BACKEND_ROOT = Path(__file__).resolve().parents[1]
sys.path.append(str(BACKEND_ROOT))

from app.core.database import (  # noqa: E402
    Base,
    SessionLocal,
    engine,
    ensure_schema_compatibility,
)
from app.domain.announcements.models import (  # noqa: E402
    Condition,
    Status,
    TradeAnnouncement,
)
from app.domain.books.models import (  # noqa: E402
    Book,
    Edition,
    Genre,
    Language,
)
from app.domain.locations.models import Location as Location  # noqa: E402
from app.domain.offer.models import (  # noqa: E402
    Offer,
    OfferedAnnouncements,
    StatusOffer,
)
from app.domain.users.models import User  # noqa: E402


USERS = {
    "ana": "11111111-1111-1111-1111-111111111111",
    "bruno": "22222222-2222-2222-2222-222222222222",
    "carla": "33333333-3333-3333-3333-333333333333",
    "diego": "44444444-4444-4444-4444-444444444444",
    "eva": "55555555-5555-5555-5555-555555555555",
    "sem_localizacao": "66666666-6666-6666-6666-666666666666",
}

ANNOUNCEMENTS = {
    "ana_clean_code": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaa0001",
    "ana_dom_casmurro": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaa0002",
    "bruno_dune": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0001",
    "bruno_hobbit": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0002",
    "carla_capitaes": "cccccccc-cccc-cccc-cccc-cccccccc0001",
    "carla_sertao": "cccccccc-cccc-cccc-cccc-cccccccc0002",
    "diego_alienista": "dddddddd-dddd-dddd-dddd-dddddddd0001",
    "eva_design_patterns": "eeeeeeee-eeee-eeee-eeee-eeeeeeee0001",
    "sem_localizacao_python": "ffffffff-ffff-ffff-ffff-ffffffff0001",
}

OFFERS = {
    "bruno_para_ana": "99999999-9999-9999-9999-999999990001",
    "carla_para_ana": "99999999-9999-9999-9999-999999990002",
    "diego_para_ana_rejected": "99999999-9999-9999-9999-999999990003",
    "ana_para_bruno": "99999999-9999-9999-9999-999999990004",
}


def reset_demo_data(db):
    """
    Limpa as tabelas principais para recriar um cenário consistente.

    Ordem de remoção:
    1. offered_announcements
    2. offer
    3. trade_announcements
    4. editions
    5. books
    6. users
    7. locations
    """

    db.query(OfferedAnnouncements).delete(synchronize_session=False)
    db.query(Offer).delete(synchronize_session=False)
    db.query(TradeAnnouncement).delete(synchronize_session=False)
    db.query(Edition).delete(synchronize_session=False)
    db.query(Book).delete(synchronize_session=False)
    db.query(User).delete(synchronize_session=False)
    db.query(Location).delete(synchronize_session=False)
    db.commit()


def make_schema_compatible():
    """
    Garante compatibilidade com bancos locais antigos.

    A branch atual usa users.cep_id e trade_announcements.cep_id.
    Se o banco local ainda tiver users.cep, copiamos o valor antigo
    para cep_id quando possível.
    """

    Base.metadata.create_all(bind=engine)
    ensure_schema_compatibility()

    with engine.begin() as connection:
        connection.execute(
            text(
                """
                DO $$
                BEGIN
                    IF EXISTS (
                        SELECT 1
                        FROM information_schema.columns
                        WHERE table_name = 'users'
                          AND column_name = 'cep'
                    ) THEN
                        UPDATE users
                        SET cep_id = cep
                        WHERE cep_id IS NULL;
                    END IF;
                END $$;
                """
            )
        )


def create_locations(db):
    """
    Cria localizações com CEPs reais e coordenadas aproximadas.

    As coordenadas são inseridas diretamente para evitar depender de API externa
    durante o seed. A feature de distância usa lat/long salvos no banco.
    """

    locations = [
        Location(
            cep="13083970",
            city="Campinas",
            state="SP",
            country="Brasil",
            district="Cidade Universitária",
            lat=-22.8179,
            long=-47.0695,
        ),
        Location(
            cep="01310200",
            city="São Paulo",
            state="SP",
            country="Brasil",
            district="Bela Vista",
            lat=-23.5614,
            long=-46.6559,
        ),
        Location(
            cep="22070002",
            city="Rio de Janeiro",
            state="RJ",
            country="Brasil",
            district="Copacabana",
            lat=-22.9711,
            long=-43.1822,
        ),
        Location(
            cep="30140010",
            city="Belo Horizonte",
            state="MG",
            country="Brasil",
            district="Savassi",
            lat=-19.9320,
            long=-43.9378,
        ),
        Location(
            cep="80060000",
            city="Curitiba",
            state="PR",
            country="Brasil",
            district="Centro",
            lat=-25.4284,
            long=-49.2671,
        ),
        Location(
            cep="01001000",
            city="São Paulo",
            state="SP",
            country="Brasil",
            district="Sé",
            lat=None,
            long=None,
        ),
    ]

    db.add_all(locations)
    db.commit()


def create_users(db):
    users = [
        User(
            id=USERS["ana"],
            username="ana_campinas",
            email="ana.campinas@example.com",
            full_name="Ana Campinas",
            cep_id="13083970",
        ),
        User(
            id=USERS["bruno"],
            username="bruno_sp",
            email="bruno.sp@example.com",
            full_name="Bruno São Paulo",
            cep_id="01310200",
        ),
        User(
            id=USERS["carla"],
            username="carla_rio",
            email="carla.rio@example.com",
            full_name="Carla Rio",
            cep_id="22070002",
        ),
        User(
            id=USERS["diego"],
            username="diego_bh",
            email="diego.bh@example.com",
            full_name="Diego Belo Horizonte",
            cep_id="30140010",
        ),
        User(
            id=USERS["eva"],
            username="eva_curitiba",
            email="eva.curitiba@example.com",
            full_name="Eva Curitiba",
            cep_id="80060000",
        ),
        User(
            id=USERS["sem_localizacao"],
            username="usuario_sem_localizacao",
            email="sem.localizacao@example.com",
            full_name="Usuário Sem Localização",
            cep_id=None,
        ),
    ]

    db.add_all(users)
    db.commit()


def create_book_with_edition(
    db,
    *,
    title: str,
    author: str,
    genre: Genre,
    synopsis: str,
    publisher: str,
    publish_year: int,
    pages: int,
    language: Language,
):
    book = Book(
        title=title,
        author=author,
        genre=genre,
        synopsis=synopsis,
    )

    db.add(book)
    db.flush()

    edition = Edition(
        book_id=book.id,
        publisher=publisher,
        publish_year=publish_year,
        number_of_pages=pages,
        language=language,
    )

    db.add(edition)
    db.flush()

    return book, edition


def create_announcement(
    db,
    *,
    announcement_id: str,
    user_id: str,
    edition_id: str,
    cep_id: str | None,
    photo_seed: str,
    condition: Condition,
    description: str,
    days_ago: int,
    status: Status = Status.Available,
):
    announcement = TradeAnnouncement(
        id=announcement_id,
        user_id=user_id,
        edition_id=edition_id,
        cep_id=cep_id,
        real_photo_url=f"https://picsum.photos/seed/{photo_seed}/400/600",
        condition=condition,
        description=description,
        create_date=datetime.utcnow() - timedelta(days=days_ago),
        status=status,
    )

    db.add(announcement)
    db.flush()

    return announcement


def create_books_and_announcements(db):
    clean_code_book, clean_code_edition = create_book_with_edition(
        db,
        title="Clean Code",
        author="Robert C. Martin",
        genre=Genre.Education,
        synopsis="Livro sobre boas práticas de programação e organização de código.",
        publisher="Prentice Hall",
        publish_year=2008,
        pages=464,
        language=Language.En,
    )

    dom_casmurro_book, dom_casmurro_edition = create_book_with_edition(
        db,
        title="Dom Casmurro",
        author="Machado de Assis",
        genre=Genre.Romance,
        synopsis="Romance brasileiro clássico sobre memória, ciúme e ambiguidade.",
        publisher="Editora Garnier",
        publish_year=1899,
        pages=256,
        language=Language.PT_br,
    )

    dune_book, dune_edition = create_book_with_edition(
        db,
        title="Dune",
        author="Frank Herbert",
        genre=Genre.Sci_fic,
        synopsis="Ficção científica sobre política, ecologia e poder em um planeta desértico.",
        publisher="Chilton Books",
        publish_year=1965,
        pages=688,
        language=Language.En,
    )

    hobbit_book, hobbit_edition = create_book_with_edition(
        db,
        title="O Hobbit",
        author="J. R. R. Tolkien",
        genre=Genre.Fantasy,
        synopsis="Aventura de fantasia envolvendo uma jornada inesperada.",
        publisher="HarperCollins",
        publish_year=1937,
        pages=310,
        language=Language.PT_br,
    )

    capitaes_book, capitaes_edition = create_book_with_edition(
        db,
        title="Capitães da Areia",
        author="Jorge Amado",
        genre=Genre.Romance,
        synopsis="Romance brasileiro sobre juventude, desigualdade e vida urbana.",
        publisher="Companhia das Letras",
        publish_year=1937,
        pages=280,
        language=Language.PT_br,
    )

    sertao_book, sertao_edition = create_book_with_edition(
        db,
        title="Grande Sertão: Veredas",
        author="João Guimarães Rosa",
        genre=Genre.Romance,
        synopsis="Narrativa literária ambientada no sertão brasileiro.",
        publisher="Nova Fronteira",
        publish_year=1956,
        pages=624,
        language=Language.PT_br,
    )

    alienista_book, alienista_edition = create_book_with_edition(
        db,
        title="O Alienista",
        author="Machado de Assis",
        genre=Genre.Romance,
        synopsis="Novela satírica sobre ciência, normalidade e poder social.",
        publisher="Lombaerts",
        publish_year=1882,
        pages=96,
        language=Language.PT_br,
    )

    design_patterns_book, design_patterns_edition = create_book_with_edition(
        db,
        title="Design Patterns",
        author="Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides",
        genre=Genre.Education,
        synopsis="Livro clássico sobre padrões de projeto em software.",
        publisher="Addison-Wesley",
        publish_year=1994,
        pages=395,
        language=Language.En,
    )

    python_book, python_edition = create_book_with_edition(
        db,
        title="Python Para Testes",
        author="Autor Demo",
        genre=Genre.Education,
        synopsis="Livro fictício usado para testar anúncio sem localização.",
        publisher="Editora Demo",
        publish_year=2021,
        pages=210,
        language=Language.PT_br,
    )

    announcements = [
        create_announcement(
            db,
            announcement_id=ANNOUNCEMENTS["ana_clean_code"],
            user_id=USERS["ana"],
            edition_id=clean_code_edition.id,
            cep_id="13083970",
            photo_seed="clean-code-campinas",
            condition=Condition.Good,
            description="Exemplar conservado, com poucas marcações.",
            days_ago=1,
        ),
        create_announcement(
            db,
            announcement_id=ANNOUNCEMENTS["ana_dom_casmurro"],
            user_id=USERS["ana"],
            edition_id=dom_casmurro_edition.id,
            cep_id="13083970",
            photo_seed="dom-casmurro-campinas",
            condition=Condition.Used,
            description="Livro usado, mas em bom estado para leitura.",
            days_ago=6,
        ),
        create_announcement(
            db,
            announcement_id=ANNOUNCEMENTS["bruno_dune"],
            user_id=USERS["bruno"],
            edition_id=dune_edition.id,
            cep_id="01310200",
            photo_seed="dune-sao-paulo",
            condition=Condition.Good,
            description="Edição em bom estado, sem páginas rasgadas.",
            days_ago=2,
        ),
        create_announcement(
            db,
            announcement_id=ANNOUNCEMENTS["bruno_hobbit"],
            user_id=USERS["bruno"],
            edition_id=hobbit_edition.id,
            cep_id="01310200",
            photo_seed="hobbit-sao-paulo",
            condition=Condition.New,
            description="Livro praticamente novo.",
            days_ago=8,
        ),
        create_announcement(
            db,
            announcement_id=ANNOUNCEMENTS["carla_capitaes"],
            user_id=USERS["carla"],
            edition_id=capitaes_edition.id,
            cep_id="22070002",
            photo_seed="capitaes-rio",
            condition=Condition.Good,
            description="Capa com leves marcas de uso.",
            days_ago=3,
        ),
        create_announcement(
            db,
            announcement_id=ANNOUNCEMENTS["carla_sertao"],
            user_id=USERS["carla"],
            edition_id=sertao_edition.id,
            cep_id="22070002",
            photo_seed="sertao-rio",
            condition=Condition.Used,
            description="Livro antigo, completo e legível.",
            days_ago=9,
        ),
        create_announcement(
            db,
            announcement_id=ANNOUNCEMENTS["diego_alienista"],
            user_id=USERS["diego"],
            edition_id=alienista_edition.id,
            cep_id="30140010",
            photo_seed="alienista-bh",
            condition=Condition.Good,
            description="Exemplar em bom estado geral.",
            days_ago=4,
        ),
        create_announcement(
            db,
            announcement_id=ANNOUNCEMENTS["eva_design_patterns"],
            user_id=USERS["eva"],
            edition_id=design_patterns_edition.id,
            cep_id="80060000",
            photo_seed="design-patterns-curitiba",
            condition=Condition.Good,
            description="Livro técnico conservado.",
            days_ago=5,
        ),
        create_announcement(
            db,
            announcement_id=ANNOUNCEMENTS["sem_localizacao_python"],
            user_id=USERS["sem_localizacao"],
            edition_id=python_edition.id,
            cep_id=None,
            photo_seed="python-sem-localizacao",
            condition=Condition.Good,
            description="Anúncio sem localização para testar fallback.",
            days_ago=7,
        ),
    ]

    db.commit()

    return announcements


def create_offer(
    db,
    *,
    offer_id: str,
    requester_user_id: str,
    target_announcement_id: str,
    offered_announcement_ids: list[str],
    status_offer: StatusOffer,
    hours_ago: int,
):
    offer = Offer(
        id=offer_id,
        user_id=requester_user_id,
        target_announcement_id=target_announcement_id,
        status_offer=status_offer,
        created_at=datetime.now(timezone.utc) - timedelta(hours=hours_ago),
    )

    db.add(offer)
    db.flush()

    for announcement_id in offered_announcement_ids:
        db.add(
            OfferedAnnouncements(
                offer_id=offer.id,
                offered_announcement_id=announcement_id,
            )
        )

    db.flush()

    return offer


def create_offers(db):
    """
    Cria propostas para testar a feature anterior.

    Cenário principal:
    - Ana é dona do anúncio Clean Code.
    - Bruno, Carla e Diego fizeram propostas para esse anúncio.
    - Duas propostas ficam Pending.
    - Uma proposta já fica Rejected.

    Isso permite testar:
    GET /api/v1/offers/received?owner_user_id=<ANA_ID>
    GET /api/v1/offers/{offer_id}?owner_user_id=<ANA_ID>
    PATCH /api/v1/offers/{offer_id}/accept?owner_user_id=<ANA_ID>
    PATCH /api/v1/offers/{offer_id}/reject?owner_user_id=<ANA_ID>
    """

    create_offer(
        db,
        offer_id=OFFERS["bruno_para_ana"],
        requester_user_id=USERS["bruno"],
        target_announcement_id=ANNOUNCEMENTS["ana_clean_code"],
        offered_announcement_ids=[
            ANNOUNCEMENTS["bruno_dune"],
            ANNOUNCEMENTS["bruno_hobbit"],
        ],
        status_offer=StatusOffer.Pending,
        hours_ago=2,
    )

    create_offer(
        db,
        offer_id=OFFERS["carla_para_ana"],
        requester_user_id=USERS["carla"],
        target_announcement_id=ANNOUNCEMENTS["ana_clean_code"],
        offered_announcement_ids=[
            ANNOUNCEMENTS["carla_capitaes"],
        ],
        status_offer=StatusOffer.Pending,
        hours_ago=5,
    )

    create_offer(
        db,
        offer_id=OFFERS["diego_para_ana_rejected"],
        requester_user_id=USERS["diego"],
        target_announcement_id=ANNOUNCEMENTS["ana_clean_code"],
        offered_announcement_ids=[
            ANNOUNCEMENTS["diego_alienista"],
        ],
        status_offer=StatusOffer.Rejected,
        hours_ago=12,
    )

    create_offer(
        db,
        offer_id=OFFERS["ana_para_bruno"],
        requester_user_id=USERS["ana"],
        target_announcement_id=ANNOUNCEMENTS["bruno_dune"],
        offered_announcement_ids=[
            ANNOUNCEMENTS["ana_dom_casmurro"],
        ],
        status_offer=StatusOffer.Pending,
        hours_ago=8,
    )

    db.commit()


def print_summary():
    print("\nSeed concluído com sucesso.\n")

    print("Usuários principais:")
    print(f"  Ana Campinas      : {USERS['ana']}")
    print(f"  Bruno São Paulo   : {USERS['bruno']}")
    print(f"  Carla Rio         : {USERS['carla']}")
    print(f"  Diego BH          : {USERS['diego']}")
    print(f"  Eva Curitiba      : {USERS['eva']}")
    print(f"  Sem localização   : {USERS['sem_localizacao']}")

    print("\nPara testar ordenação por distância no Swagger:")
    print(
        "  GET /api/v1/announcements/feed"
        f"?current_user_id={USERS['ana']}&sort_by_distance=true"
    )

    print("\nPara testar solicitações recebidas da feature anterior:")
    print(
        "  GET /api/v1/offers/received"
        f"?owner_user_id={USERS['ana']}"
    )

    print("\nOfertas criadas para a Ana:")
    print(f"  Bruno -> Ana Pending   : {OFFERS['bruno_para_ana']}")
    print(f"  Carla -> Ana Pending   : {OFFERS['carla_para_ana']}")
    print(f"  Diego -> Ana Rejected  : {OFFERS['diego_para_ana_rejected']}")

    print("\nComando Flutter sugerido:")
    print(
        "  flutter run "
        "--dart-define=API_BASE_URL=http://10.0.2.2:8000 "
        f"--dart-define=CURRENT_USER_ID={USERS['ana']}"
    )
    print()


def main():
    make_schema_compatible()

    db = SessionLocal()

    try:
        reset_demo_data(db)
        create_locations(db)
        create_users(db)
        create_books_and_announcements(db)
        create_offers(db)
        print_summary()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()