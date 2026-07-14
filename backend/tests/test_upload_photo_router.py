import pytest
from fastapi.testclient import TestClient
from app.main import app 

client = TestClient(app)

def test_upload_photo_endpoint(mocker):
    # 1. Mockamos APENAS a função que é efetivamente importada e usada no router
    # 2. Em vez de retornar True, retornamos um dicionário que imita o schema 'PhotoResponse'
    fake_photo_response = {
        "id": "foto-fake-123",
        "trade_announcement_id": "ann-123",
        "photo_url": "http://fake-url.com/foto.jpg"
    }
    
    mock_add = mocker.patch(
        "app.api.v1.announcements.router.add_photo_to_announcement", 
        return_value=fake_photo_response
    )

    # Simula o envio de um arquivo Multipart
    response = client.post(
        "/api/v1/announcements/ann-123/photos",
        files={"file": ("foto.jpg", b"fakebytes", "image/jpeg")}
    )
    
    # A sua rota usa status_code=status.HTTP_201_CREATED
    assert response.status_code == 201 
    mock_add.assert_called_once()
    assert response.json()["photo_url"] == "http://fake-url.com/foto.jpg"

def test_delete_photo_endpoint(mocker):
    # Mocka as duas funções exatamente no local onde elas foram importadas (o router)
    mock_delete_s3 = mocker.patch("app.api.v1.announcements.router.delete_image_from_supabase", return_value=True)
    mock_delete_db = mocker.patch("app.api.v1.announcements.router.remove_photo_from_announcement", return_value=True)

    # Envia a URL no formato JSON esperado pela sua classe DeletePhotoRequest
    response = client.request(
        "DELETE", 
        "/api/v1/announcements/ann-123/photos",
        json={"photo_url": "http://fake-url.com/foto.jpg"}
    )
    
    assert response.status_code == 200
    mock_delete_s3.assert_called_once()
    mock_delete_db.assert_called_once()