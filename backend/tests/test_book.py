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

class TestCreateBook:
    def test_create_book(self, client, mock_db):
        response = client.post(
            "/api/v1/books",
            json={
                "title": "The Great Gatsby",
                "author": "F. Scott Fitzgerald",
                "genre": "Fiction",
                "synopsis": "A novel set in the Roaring Twenties."
            }
        )

        assert response.status_code == 201
        
        data = response.json()
        assert data["message"] == "Book created successfully"
        assert "bookId" in data
        
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()

    def test_create_book_dados_invalid_data(client):
        # falta coisas como title e genre tem um valor que não existe no Enum
        payload_ruim = {
            "author": "F. Scott Fitzgerald",
            "genre": "Ficção", # Valor que não existe no Enum!
            "synopsis": "A novel set in the Roaring Twenties."
        }

        response = client.post("/api/v1/books", json=payload_ruim)

        assert response.status_code == 422
        
        erros = response.json()["detail"]
        campos_com_erro = [erro["loc"][-1] for erro in erros]
        
        assert "title" in campos_com_erro 
        assert "genre" in campos_com_erro