from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db

# Importamos o nosso "cozinheiro"
from . import services 

router = APIRouter(
    prefix="/users",
    tags=["Users"],
)

@router.get("/")
def get_users(db: Session = Depends(get_db)):
    # 1. O Router anota o pedido e passa a "panela" (db) para o Service
    users = services.get_users(db=db, limit=5)
    
    # 2. O Router pega a resposta do Service e devolve para o garçom (Flutter)
    return users