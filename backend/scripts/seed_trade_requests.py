from datetime import datetime
from uuid import uuid4
from app.domain.locations import models as location_models

from app.core.database import Base, SessionLocal, engine
from app.domain.announcements.models import (
    Condition,
    Status,
    TradeAnnouncement,
)
from app.domain.books.models import (
    Book,
    Edition,
    Genre,
    Language,
)
from app.domain.offer.models import (
    Offer,
    OfferedAnnouncements,
    StatusOffer,
)
from app.domain.users.models import User


def create_book_with_edition(
    *,
    title: str,
    author: str,
    publisher: str,
    publish_year: int,
    genre: Genre = Genre.Fantasy,
) -> tuple[Book, Edition]:
    book = Book(
        id=str(uuid4()),
        title=title,
        author=author,
        genre=genre,
        synopsis=f"Sinopse de teste para {title}.",
    )

    edition = Edition(
        id=str(uuid4()),
        book=book,
        publisher=publisher,
        publish_year=publish_year,
        number_of_pages=300,
        language=Language.PT_br,
    )

    return book, edition


def create_announcement(
    *,
    user: User,
    edition: Edition,
    description: str,
    condition: Condition = Condition.Good,
) -> TradeAnnouncement:
    return TradeAnnouncement(
        id=str(uuid4()),
        user=user,
        edition=edition,
        real_photo_url=None,
        condition=condition,
        description=description,
        create_date=datetime.utcnow(),
        status=Status.Available,
    )


def main() -> None:
    # Cria as tabelas que ainda não existirem.
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()

    try:
        suffix = uuid4().hex[:8]

        # ---------------------------------------------------------
        # USUÁRIOS
        # ---------------------------------------------------------

        owner = User(
            id=str(uuid4()),
            username=f"victor_owner_{suffix}",
            email=f"victor_owner_{suffix}@example.com",
            full_name="Victor Dono dos Anúncios",
            cep="13083852",
        )

        requester_one = User(
            id=str(uuid4()),
            username=f"interessado_um_{suffix}",
            email=f"interessado_um_{suffix}@example.com",
            full_name="Usuário Interessado Um",
            cep="11010000",
        )

        requester_two = User(
            id=str(uuid4()),
            username=f"interessado_dois_{suffix}",
            email=f"interessado_dois_{suffix}@example.com",
            full_name="Usuário Interessado Dois",
            cep="01001000",
        )

        db.add_all([owner, requester_one, requester_two])

        # ---------------------------------------------------------
        # LIVROS E EDIÇÕES
        # ---------------------------------------------------------

        algernon_book, algernon_edition = create_book_with_edition(
            title="Flores para Algernon",
            author="Daniel Keyes",
            publisher="Editora Aleph",
            publish_year=2000,
            genre=Genre.Sci_fic,
        )

        dune_book, dune_edition = create_book_with_edition(
            title="Duna",
            author="Frank Herbert",
            publisher="Editora Aleph",
            publish_year=2017,
            genre=Genre.Sci_fic,
        )

        nineteen_book, nineteen_edition = create_book_with_edition(
            title="1984",
            author="George Orwell",
            publisher="Companhia das Letras",
            publish_year=2009,
            genre=Genre.Sci_fic,
        )

        descartes_book, descartes_edition = create_book_with_edition(
            title="Discurso do Método",
            author="René Descartes",
            publisher="Martin Claret",
            publish_year=2004,
            genre=Genre.Education,
        )

        hobbit_book, hobbit_edition = create_book_with_edition(
            title="O Hobbit",
            author="J. R. R. Tolkien",
            publisher="HarperCollins",
            publish_year=2019,
            genre=Genre.Fantasy,
        )

        db.add_all(
            [
                algernon_book,
                algernon_edition,
                dune_book,
                dune_edition,
                nineteen_book,
                nineteen_edition,
                descartes_book,
                descartes_edition,
                hobbit_book,
                hobbit_edition,
            ]
        )

        # ---------------------------------------------------------
        # ANÚNCIOS
        # ---------------------------------------------------------

        algernon_announcement = create_announcement(
            user=owner,
            edition=algernon_edition,
            description="Exemplar de Flores para Algernon.",
            condition=Condition.Good,
        )

        dune_announcement = create_announcement(
            user=owner,
            edition=dune_edition,
            description="Exemplar de Duna.",
            condition=Condition.Used,
        )

        nineteen_announcement = create_announcement(
            user=requester_one,
            edition=nineteen_edition,
            description="Exemplar de 1984 disponível para troca.",
            condition=Condition.Good,
        )

        descartes_announcement = create_announcement(
            user=requester_one,
            edition=descartes_edition,
            description="Livro de Descartes disponível.",
            condition=Condition.Used,
        )

        hobbit_announcement = create_announcement(
            user=requester_two,
            edition=hobbit_edition,
            description="O Hobbit disponível para troca.",
            condition=Condition.New,
        )

        db.add_all(
            [
                algernon_announcement,
                dune_announcement,
                nineteen_announcement,
                descartes_announcement,
                hobbit_announcement,
            ]
        )

        # Flush garante que os registros estejam disponíveis antes
        # de criarmos as ofertas e seus relacionamentos.
        db.flush()

        # ---------------------------------------------------------
        # OFERTA 1: pendente, com dois livros oferecidos
        # ---------------------------------------------------------

        pending_offer = Offer(
            id=str(uuid4()),
            user=requester_one,
            target_announcement=algernon_announcement,
            status_offer=StatusOffer.Pending,
        )

        pending_offer.offered_announcements = [
            OfferedAnnouncements(
                offered_announcement_id=nineteen_announcement.id,
            ),
            OfferedAnnouncements(
                offered_announcement_id=descartes_announcement.id,
            ),
        ]

        # ---------------------------------------------------------
        # OFERTA 2: concorrente para o mesmo anúncio
        #
        # Ao aceitar a oferta 1, esta deve ser cancelada.
        # ---------------------------------------------------------

        competing_offer = Offer(
            id=str(uuid4()),
            user=requester_two,
            target_announcement=algernon_announcement,
            status_offer=StatusOffer.Pending,
        )

        competing_offer.offered_announcements = [
            OfferedAnnouncements(
                offered_announcement_id=hobbit_announcement.id,
            ),
        ]

        # ---------------------------------------------------------
        # OFERTA 3: já recusada, para testar o badge/status
        # ---------------------------------------------------------

        rejected_offer = Offer(
            id=str(uuid4()),
            user=requester_two,
            target_announcement=dune_announcement,
            status_offer=StatusOffer.Rejected,
        )

        rejected_offer.offered_announcements = [
            OfferedAnnouncements(
                offered_announcement_id=hobbit_announcement.id,
            ),
        ]

        db.add_all(
            [
                pending_offer,
                competing_offer,
                rejected_offer,
            ]
        )

        db.commit()

        print()
        print("=" * 70)
        print("DADOS DE TESTE CRIADOS COM SUCESSO")
        print("=" * 70)
        print(f"CURRENT_USER_ID={owner.id}")
        print()
        print(f"Oferta pendente principal: {pending_offer.id}")
        print(f"Oferta concorrente:       {competing_offer.id}")
        print(f"Oferta já recusada:       {rejected_offer.id}")
        print()
        print("Use no Flutter:")
        print(
            "flutter run "
            "--dart-define=API_BASE_URL=http://10.0.2.2:8000 "
            f"--dart-define=CURRENT_USER_ID={owner.id}"
        )
        print("=" * 70)

    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()