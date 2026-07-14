import os
import uuid
import boto3
from fastapi import UploadFile
from dotenv import load_dotenv
import urllib.parse

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
    
    
    
def delete_image_from_supabase(photo_url: str) -> bool:
    """
    Recebe a URL pública da foto, extrai a chave (path) e deleta do Supabase S3.
    """
    try:
        if BUCKET_NAME in photo_url:
            # 1. Corta a URL
            object_key_encoded = photo_url.split(f"{BUCKET_NAME}/")[-1]
            
            # 2. Transforma "%20" de volta em espaço (Proteção essencial para S3!)
            object_key = urllib.parse.unquote(object_key_encoded)
            
            print(f"Deletando do S3 -> Bucket: {BUCKET_NAME} | Key: {object_key}")
            
            # 3. Chama o boto3
            s3_client.delete_object(
                Bucket=BUCKET_NAME,
                Key=object_key
            )
            return True
        else:
            raise Exception("URL inválida ou bucket incorreto.")

    except Exception as e:
        raise Exception(f"Erro ao deletar a imagem no Supabase: {str(e)}")