from fastapi import APIRouter, Depends, Response
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.domain.auth import schemas, services

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])


@router.post("/register", response_model=schemas.TokenResponse, status_code=201)
def register(body: schemas.RegisterRequest, db: Session = Depends(get_db)):
    return services.register(db, body)


@router.post("/login", response_model=schemas.TokenResponse)
def login(body: schemas.LoginRequest, db: Session = Depends(get_db)):
    return services.login(db, str(body.email), body.password)


@router.post("/refresh", response_model=schemas.TokenResponse)
def refresh(body: schemas.RefreshRequest, db: Session = Depends(get_db)):
    return services.refresh(db, body.refresh_token)


@router.post("/logout", status_code=204)
def logout(body: schemas.LogoutRequest, db: Session = Depends(get_db)):
    services.logout(db, body.refresh_token)
    return Response(status_code=204)
