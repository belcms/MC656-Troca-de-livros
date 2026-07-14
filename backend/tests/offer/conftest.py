from datetime import datetime, timedelta
from typing import Callable, Dict, Generator

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.api.v1.offer.router import router_offer
from app.core.database import get_db
from app.domain.announcements.models import Condition, Status, TradeAnnouncement
from app.domain.offer.models import Offer, OfferedAnnouncements, StatusOffer
from app.domain.users.models import User


@pytest.fixture
def offer_client(
    db_session: Session,
) -> Generator[TestClient, None, None]:
    """Cliente HTTP com o router de ofertas e o SQLite de testes."""
    app = FastAPI()
    app.include_router(router_offer)

    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    try:
        with TestClient(app) as client:
            yield client
    finally:
        app.dependency_overrides.clear()


@pytest.fixture
def seed_offer_scenario(
    db_session: Session,
    seed_announcement: Callable[..., Dict[str, object]],
) -> Callable[[], Dict[str, object]]:
    """Monta um cenário completo para os testes de solicitações de troca."""

    def create_user(
        *,
        username: str,
        full_name: str | None,
        cep: str | None = "13000000",
    ) -> User:
        user = User(
            username=username,
            email=f"{username}@example.com",
            full_name=full_name,
            cep=cep,
        )
        db_session.add(user)
        db_session.flush()
        return user

    def add_offer(
        *,
        requester: User,
        target: TradeAnnouncement,
        offered: list[TradeAnnouncement],
        status: StatusOffer = StatusOffer.Pending,
        created_at: datetime,
    ) -> Offer:
        offer = Offer(
            user_id=requester.id,
            target_announcement_id=target.id,
            status_offer=status,
            created_at=created_at,
        )
        db_session.add(offer)
        db_session.flush()

        for announcement in offered:
            db_session.add(
                OfferedAnnouncements(
                    offer_id=offer.id,
                    offered_announcement_id=announcement.id,
                )
            )

        db_session.flush()
        return offer

    def _seed() -> Dict[str, object]:
        owner = create_user(
            username="owner",
            full_name="Dona do anúncio",
            cep="13010000",
        )
        requester_main = create_user(
            username="requester_main",
            full_name="Pessoa Interessada",
            cep="11020000",
        )
        requester_competing = create_user(
            username="requester_competing",
            full_name="Outro Interessado",
            cep="12030000",
        )
        outsider = create_user(
            username="outsider",
            full_name="Usuário de Fora",
            cep="14040000",
        )

        target_data = seed_announcement(
            user=owner,
            title="Flores para Algernon",
            publish_year=2000,
            condition=Condition.Good,
        )
        second_target_data = seed_announcement(
            user=owner,
            title="Duna",
            publish_year=2017,
            condition=Condition.Used,
        )
        outsider_target_data = seed_announcement(
            user=outsider,
            title="Livro de outro dono",
            publish_year=2018,
        )

        offered_1984_data = seed_announcement(
            user=requester_main,
            title="1984",
            publish_year=2009,
            condition=Condition.Used,
        )
        offered_descartes_data = seed_announcement(
            user=requester_main,
            title="Discurso do Método",
            publish_year=2004,
            condition=Condition.Good,
        )
        offered_hobbit_data = seed_announcement(
            user=requester_competing,
            title="O Hobbit",
            publish_year=2019,
            condition=Condition.New,
        )
        offered_outsider_data = seed_announcement(
            user=requester_main,
            title="Livro oferecido a terceiro",
            publish_year=2020,
        )

        now = datetime(2026, 7, 12, 12, 0, 0)

        main_offer = add_offer(
            requester=requester_main,
            target=target_data["announcement"],
            offered=[
                offered_1984_data["announcement"],
                offered_descartes_data["announcement"],
            ],
            status=StatusOffer.Pending,
            created_at=now,
        )
        competing_offer = add_offer(
            requester=requester_competing,
            target=target_data["announcement"],
            offered=[offered_hobbit_data["announcement"]],
            status=StatusOffer.Pending,
            created_at=now - timedelta(minutes=10),
        )
        rejected_offer = add_offer(
            requester=requester_main,
            target=second_target_data["announcement"],
            offered=[offered_1984_data["announcement"]],
            status=StatusOffer.Rejected,
            created_at=now - timedelta(minutes=20),
        )
        outsider_offer = add_offer(
            requester=requester_main,
            target=outsider_target_data["announcement"],
            offered=[offered_outsider_data["announcement"]],
            status=StatusOffer.Pending,
            created_at=now + timedelta(minutes=10),
        )

        db_session.commit()

        return {
            "owner": owner,
            "requester_main": requester_main,
            "requester_competing": requester_competing,
            "outsider": outsider,
            "target": target_data["announcement"],
            "second_target": second_target_data["announcement"],
            "outsider_target": outsider_target_data["announcement"],
            "offered_1984": offered_1984_data["announcement"],
            "offered_descartes": offered_descartes_data["announcement"],
            "offered_hobbit": offered_hobbit_data["announcement"],
            "offered_outsider": offered_outsider_data["announcement"],
            "main_offer": main_offer,
            "competing_offer": competing_offer,
            "rejected_offer": rejected_offer,
            "outsider_offer": outsider_offer,
        }

    return _seed
