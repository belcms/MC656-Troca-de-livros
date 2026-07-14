import pytest
from fastapi.testclient import TestClient
from app.main import app 

client = TestClient(app)

# ==========================================
# 1. TESTES DAS FUNÇÕES DE SERVIÇO (S3 / BOTO3)
# ==========================================

def test_upload_image_to_supabase_success(mocker):
    # Mocka o s3_client para não fazer upload de verdade
    mock_s3 = mocker.patch("app.services.storage_service.s3_client") # Ajuste o caminho do import!
    
    # Cria um UploadFile falso
    from fastapi import UploadFile
    import io
    fake_file = UploadFile(filename="teste.jpg", file=io.BytesIO(b"fake_image_data"))
    
    # Chama a sua função real (que está mockada por dentro)
    from app.services.storage_service import upload_image_to_supabase # Ajuste o caminho!
    url_retornada = upload_image_to_supabase(fake_file)
    
    # Verifica se o S3 foi chamado e se a URL tem o formato esperado
    mock_s3.upload_fileobj.assert_called_once()
    assert ".jpg" in url_retornada
    assert "object/public/" in url_retornada

def test_delete_image_from_supabase_success(mocker):
    # Mocka o S3 e a variável BUCKET_NAME
    mock_s3 = mocker.patch("app.services.storage_service.s3_client")
    mocker.patch("app.services.storage_service.BUCKET_NAME", "meu-bucket")
    
    from app.services.storage_service import delete_image_from_supabase # Ajuste o caminho!
    
    # Passa uma URL simulada
    fake_url = "https://projeto.supabase.co/storage/v1/object/public/meu-bucket/livros/teste%20foto.jpg"
    resultado = delete_image_from_supabase(fake_url)
    
    assert resultado is True
    # Verifica se ele limpou o "%20" transformando em espaço
    mock_s3.delete_object.assert_called_once_with(
        Bucket="meu-bucket",
        Key="livros/teste foto.jpg"
    )