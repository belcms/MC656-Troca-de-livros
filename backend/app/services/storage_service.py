import os
import uuid
import boto3
from fastapi import UploadFile
from dotenv import load_dotenv

load_dotenv()

ENDPOINT_URL = os.getenv("SUPABASE_S3_ENDPOINT")
ACCESS_KEY = os.getenv("SUPABASE_S3_ACCESS_KEY_ID")
SECRET_KEY = os.getenv("SUPABASE_S3_SECRET_ACCESS_KEY")
BUCKET_NAME = os.getenv("BUCKET_NAME")

s3_client = boto3.client(
    "s3",
    endpoint_url=ENDPOINT_URL,
    aws_access_key_id=ACCESS_KEY,
    aws_secret_access_key=SECRET_KEY,
    region_name="sa-east-1" 
)

def upload_image_to_supabase(file: UploadFile) -> str:
    """
    Recebe um arquivo da requisição, salva no Supabase e retorna a URL pública.
    """
    try:
        # 1. Pega a extensão original do arquivo (ex: .jpg, .png)
        file_extension = file.filename.split(".")[-1]
        
        # 2. Gera um nome único aleatório para não sobrescrever fotos com mesmo nome
        unique_filename = f"livros/{uuid.uuid4()}.{file_extension}"
        
        # 3. Faz o upload lendo os bytes do arquivo
        s3_client.upload_fileobj(
            file.file,
            BUCKET_NAME,
            unique_filename,
            ExtraArgs={"ContentType": file.content_type} # Ajuda o navegador a renderizar a imagem depois
        )
        
        # 4. Constrói a URL pública final
        # O formato do Supabase é: https://<SEU-PROJETO>.supabase.co/storage/v1/object/public/<BUCKET>/<ARQUIVO>
        project_url = ENDPOINT_URL.replace("/s3", "")
        photo_url = f"{project_url}/object/public/{BUCKET_NAME}/{unique_filename}"
        
        return photo_url

    except Exception as e:
        raise Exception(f"Erro ao fazer upload da imagem: {str(e)}")