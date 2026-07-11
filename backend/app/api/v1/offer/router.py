from typing import List

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.domain.offer.schemas import TradeRequestResponse
from app.services.offer_service import (
    accept_offer,
    get_received_offer,
    list_received_offers,
    reject_offer,
)

router_offer = APIRouter(
    prefix="/api/v1/offers",
    tags=["Offers"],
)

# Mantido porque app/main.py já importa este router.
router_offer_announcement = APIRouter(
    prefix="/api/v1/offered-announcements",
    tags=["Offered Announcements"],
)


@router_offer.get(
    "/received",
    response_model=List[TradeRequestResponse],
    response_model_by_alias=True,
)
def received_offers(
    owner_user_id: str = Query(
        ...,
        description=(
            "ID temporário do usuário autenticado. "
            "Deve ser removido quando a autenticação for implementada."
        ),
    ),
    db: Session = Depends(get_db),
):
    return list_received_offers(
        db=db,
        owner_user_id=owner_user_id,
    )


@router_offer.get(
    "/{offer_id}",
    response_model=TradeRequestResponse,
    response_model_by_alias=True,
)
def offer_details(
    offer_id: str,
    owner_user_id: str = Query(...),
    db: Session = Depends(get_db),
):
    return get_received_offer(
        db=db,
        offer_id=offer_id,
        owner_user_id=owner_user_id,
    )


@router_offer.patch(
    "/{offer_id}/accept",
    response_model=TradeRequestResponse,
    response_model_by_alias=True,
    status_code=status.HTTP_200_OK,
)
def accept_received_offer(
    offer_id: str,
    owner_user_id: str = Query(...),
    db: Session = Depends(get_db),
):
    return accept_offer(
        db=db,
        offer_id=offer_id,
        owner_user_id=owner_user_id,
    )


@router_offer.patch(
    "/{offer_id}/reject",
    response_model=TradeRequestResponse,
    response_model_by_alias=True,
    status_code=status.HTTP_200_OK,
)
def reject_received_offer(
    offer_id: str,
    owner_user_id: str = Query(...),
    db: Session = Depends(get_db),
):
    return reject_offer(
        db=db,
        offer_id=offer_id,
        owner_user_id=owner_user_id,
    )
