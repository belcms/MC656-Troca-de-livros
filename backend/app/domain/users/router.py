from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
# Importação relativa: puxa os modelos da mesma pasta 'users'
from . import models 

# Criando o "mini app" para as rotas de usuários
router = APIRouter(
    prefix="/users",
    tags=["Users"], # Isso deixa a documentação do Swagger linda e separada!
)

@router.get("/")
def get_users(db: Session = Depends(get_db)):
    # Puxa os 5 primeiros usuários do banco para testar
    users = db.query(models.User).limit(5).all()
    return users

# Você pode ir adicionando outras rotas de usuários aqui no futuro:
# @router.post("/") ...
# @router.get("/{user_id}") ...