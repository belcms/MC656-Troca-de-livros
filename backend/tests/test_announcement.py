import pytest
from unittest.mock import MagicMock
from fastapi.testclient import TestClient
import app.main as app # Substitua pelo caminho correto do seu app

@pytest.fixture(scope="module")
def client():
    return TestClient(app.app)

@pytest.fixture
def mock_db():
    mock = MagicMock()
    
    # Faz o override do get_db para usar o mock
    app.app.dependency_overrides[app.get_db] = lambda: mock
    
    # Pausa e entrega o mock para o teste 
    yield mock
    
    # Teardown: Depois que o teste acabar, limpa a sujeira
    app.app.dependency_overrides.clear()


class TestCreateAnnouncement:
    def test_create_announcement(self, client, mock_db):
        #simula requisao pro banco (mockado)
        response = client.post(
            "/api/v1/announcements/id123",
            json={
                "editionId": "id456",
                "coverUrl": "http://example.com/photo.jpg",
                "condition": "Used",
                "description": "Good condition.",
                "status": "Available"
            }
        )

        # Asserções do Comportamento da Rota (Status Code)
        assert response.status_code == 201
        
        # Asserções do Corpo da Resposta
        data = response.json()
        assert data["message"] == "Announcement created successfully"
        
        
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()

    def test_create_announcement_invalid_data(client):
        # falta coisas como editionId e condition tem um valor que não existe no Enum
        payload_ruim = {
            "coverUrl": "http://example.com/photo.jpg",
            "condition": "Novo em Folha", #!!!
            "description": "Good condition.",
            "status": "Available"
        }

        # Faz a requisição com o payload ruim
        response = client.post("/api/v1/announcements/id123", json=payload_ruim)

        # tem que retornar o erro correto do FastAPI (422 Unprocessable Entity)
        assert response.status_code == 422
        
        # Verifica se o erro menciona os campos que estão errados (editionId e condition)
        erros = response.json()["detail"]
        campos_com_erro = [erro["loc"][-1] for erro in erros]
        
        assert "editionId" in campos_com_erro 
        assert "condition" in campos_com_erro