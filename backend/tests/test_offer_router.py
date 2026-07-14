import pytest
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient
from fastapi import status
import app.services.offer_service as offer_service
from app.main import app
from app.domain.offer.schemas import OfferCreate, OfferedAnnouncementItem
from app.domain.offer.models import Offer, OfferedAnnouncements
from fastapi import FastAPI
from app.main import app 
from fastapi.testclient import TestClient

client = TestClient(app)

@patch("app.services.offer_service.create_new_offer")
def test_create_offer_endpoint_sucesso(mock_create_new_offer):
    """
    AC7: Após envio bem sucedido, retorna a mensagem correta.
    """
    # Simula o service retornando uma nova oferta com ID mockado
    mock_offer = MagicMock()
    mock_offer.id = "nova-oferta-id-123"
    mock_create_new_offer.return_value = mock_offer

    payload = {
        "userId": "user-123",
        "targetAnnouncementId": "target-456",
        "offeredAnnouncements": [{"offeredAnnouncementId": "book-1"}]
    }

    # Dispara requisição para a rota real do FastAPI
    response = client.post("/api/v1/offers/create-offer", json=payload)

    # Validações AC7
    assert response.status_code == status.HTTP_201_CREATED
    assert response.json()["message"] == "Proposta enviada com sucesso!"
    assert response.json()["offer_id"] == "nova-oferta-id-123"


@patch("app.services.offer_service.has_pending_offer")
def test_check_pending_offer_endpoint(mock_has_pending):
    """Testa o endpoint GET /check-pending."""
    # Simula o banco retornando True (usuário já tem proposta)
    mock_has_pending.return_value = True

    response = client.get("/api/v1/offers/check-pending?user_id=user-1&target_announcement_id=target-2")
    
    assert response.status_code == 200
    assert response.json() == {"hasPendingOffer": True}
    mock_has_pending.assert_called_once()