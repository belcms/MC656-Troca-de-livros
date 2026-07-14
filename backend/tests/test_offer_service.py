
import pytest
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient
from fastapi import status
import app.services.offer_service as offer_service
from app.main import app
from app.domain.offer.schemas import OfferCreate, OfferedAnnouncementItem
from app.domain.offer.models import Offer, OfferedAnnouncements

# Mock da classe OfferCreate (schema do Pydantic) para os testes
class MockOfferCreate:
    def __init__(self, userId, targetAnnouncementId, offeredAnnouncements):
        self.userId = userId
        self.targetAnnouncementId = targetAnnouncementId
        self.offeredAnnouncements = offeredAnnouncements

class MockOfferedItem:
    def __init__(self, offeredAnnouncementId):
        self.offeredAnnouncementId = offeredAnnouncementId


@pytest.fixture
def mock_db():
    """Fixture que simula a sessão do banco de dados (SQLAlchemy)"""
    return MagicMock()

def test_has_pending_offer_retorna_true(mock_db):
    """Testa se a função identifica corretamente quando JÁ EXISTE uma oferta pendente."""
    # Simula o banco de dados retornando um registro válido no .first()
    mock_db.query.return_value.filter.return_value.first.return_value = MagicMock()
    
    result = offer_service.has_pending_offer(mock_db, "user-123", "target-456")
    
    assert result is True
    # Verifica se a query foi chamada corretamente
    mock_db.query.assert_called_once()

def test_has_pending_offer_retorna_false(mock_db):
    """Testa se a função identifica corretamente quando NÃO EXISTE oferta pendente."""
    # Simula o banco de dados não encontrando nada (retornando None)
    mock_db.query.return_value.filter.return_value.first.return_value = None
    
    result = offer_service.has_pending_offer(mock_db, "user-123", "target-456")
    
    assert result is False

def test_ac5_create_new_offer_impede_duplicada(mock_db):
    """
    AC5 / AC6: O sistema deve impedir que o usuário envie uma nova proposta 
    se já existe uma pendente/em aberto.
    """
    # 1. Configuramos o mock para fingir que JÁ EXISTE uma oferta pendente
    mock_db.query.return_value.filter.return_value.first.return_value = MagicMock()
    
    offer_data = MockOfferCreate(
        userId="user-123",
        targetAnnouncementId="target-456",
        offeredAnnouncements=[MockOfferedItem("book-789")]
    )

    # 2. Ao tentar criar, deve lançar um ValueError com a mensagem exata do AC6
    with pytest.raises(ValueError) as exc_info:
        # Lembre-se: Para este teste passar, você precisa ter adicionado o 'if' 
        # que mostrei na mensagem acima dentro do seu services.py
        offer_service.create_new_offer(mock_db, offer_data)

    assert "Você já enviou uma proposta para este anúncio" in str(exc_info.value)
    
    # 3. Garante que nada foi salvo no banco (nenhum db.add foi chamado)
    mock_db.add.assert_not_called()

def test_create_new_offer_sucesso(mock_db):
    """Testa a criação bem sucedida de uma proposta (caminho feliz)."""
    # 1. Configuramos o mock para fingir que NÃO existe oferta pendente
    mock_db.query.return_value.filter.return_value.first.return_value = None
    
    offer_data = MockOfferCreate(
        userId="user-123",
        targetAnnouncementId="target-456",
        offeredAnnouncements=[
            MockOfferedItem("book-1"),
            MockOfferedItem("book-2")
        ]
    )

    # 2. Chama a função
    result = offer_service.create_new_offer(mock_db, offer_data)

    # 3. Verifica se o db.add foi chamado 3 vezes (1 capa da oferta + 2 livros oferecidos)
    assert mock_db.add.call_count == 3
    # Verifica se commit e refresh foram chamados para salvar no banco
    mock_db.commit.assert_called_once()
    mock_db.refresh.assert_called_once()



