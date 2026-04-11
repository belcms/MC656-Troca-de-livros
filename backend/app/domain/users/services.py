from sqlalchemy.orm import Session
from . import models

# Função focada APENAS em buscar dados. 
# Ela não sabe o que é uma requisição HTTP ou o que é FastAPI.
def get_users(db: Session, limit: int = 5):
    return db.query(models.User).limit(limit).all()

# No futuro, você vai adicionar aqui funções como:
# def create_user(db: Session, user_data: schemas.UserCreate): ...
# def get_user_by_email(db: Session, email: str): ...