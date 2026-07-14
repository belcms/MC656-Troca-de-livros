class TestEdition:
    def test_create_edition(self, client):
        """
        It verifies that the creation of an edition is successful
        """
        bookId = '1'
        payload = {
            "bookId": bookId,
            "publisher": "Scribner",
            "year": 1925,
            'pages': 218,
            "language": "En"
        }
        response = client.post(f"/api/v1/editions/{bookId}", json=payload)
        print(response.json())
        assert response.status_code == 201
        data = response.json()
        assert data["message"] == "Edition created successfully"
        assert "editionId" in data
    
    def test_create_edition_invalid_data(self, client):
        """
        It verifies that the creation of an edition with invalid data fails
        """
        bookId = '1'
        payload_ruim = {
            "bookId": bookId,
            "language": "Klingon",  # Valor que não existe no Enum!
            "publicationYear": 1925
        }
        response = client.post(f"/api/v1/editions/{bookId}", json=payload_ruim)
        assert response.status_code == 422
        
        erros = response.json()["detail"]
        campos_com_erro = [erro["loc"][-1] for erro in erros]
        
        assert "language" in campos_com_erro