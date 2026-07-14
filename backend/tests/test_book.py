class TestCreateBook:
    def test_create_book(self, client):
        """
        It testes the creation of a book with valid data
        """
        response = client.post(
            "/api/v1/books",
            json={
                "title": "The Great Gatsby",
                "author": "F. Scott Fitzgerald",
                "genre": "Romance",
                "synopsis": "A novel set in the Roaring Twenties."
            }
        )

        assert response.status_code == 201
        
        data = response.json()
        assert data["message"] == "Book created successfully"
        assert "bookId" in data
        

    def test_create_book_dados_invalid_data(self, client):
        """
        It tests the creation of a book with invalid data
        """
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