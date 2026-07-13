from datetime import datetime, timedelta

from fastapi import HTTPException
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.settings import settings
from app.domain.auth.schemas import RegisterRequest, UserResponse
from app.domain.auth.security import (
    encode_token,
    hash_password,
    new_refresh_token,
    token_hash,
    verify_password,
)
from app.domain.locations import services as locations_services
from app.domain.users.models import AuthSession, User


def normalized(value: str) -> str:
    return value.strip().casefold()


def user_response(user: User) -> UserResponse:
    return UserResponse(
        id=user.id,
        full_name=user.full_name,
        nickname=user.username,
        email=user.email,
        birth_date=user.birth_date,
        cep=user.cep,
    )


def _conflict(db: Session, email: str, nickname: str) -> None:
    if db.query(User).filter(User.email_normalized == normalized(email)).first():
        raise HTTPException(status_code=409, detail="E-mail já cadastrado")
    if db.query(User).filter(User.username_normalized == normalized(nickname)).first():
        raise HTTPException(status_code=409, detail="Nickname já utilizado")


def issue_session(db: Session, user: User) -> dict:
    refresh = new_refresh_token()
    session = AuthSession(
        user_id=user.id,
        refresh_token_hash=token_hash(refresh),
        expires_at=datetime.utcnow() + timedelta(days=settings.refresh_token_days),
    )
    db.add(session)
    db.commit()
    return {
        "access_token": encode_token(
            user.id,
            "access",
            timedelta(minutes=settings.access_token_minutes),
        ),
        "refresh_token": refresh,
        "token_type": "bearer",
        "user": user_response(user),
    }


def register(db: Session, body: RegisterRequest) -> dict:
    _conflict(db, str(body.email), body.nickname)
    location = locations_services.get_or_create_location_by_cep(body.cep, db)
    user = User(
        username=body.nickname,
        username_normalized=normalized(body.nickname),
        email=str(body.email).lower(),
        email_normalized=normalized(str(body.email)),
        full_name=body.full_name,
        cep_id=location.cep,
        birth_date=body.birth_date,
        password_hash=hash_password(body.password),
    )
    db.add(user)
    try:
        db.flush()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="E-mail ou nickname já cadastrado")
    return issue_session(db, user)


def login(db: Session, email: str, password: str) -> dict:
    user = db.query(User).filter(User.email_normalized == normalized(email)).first()
    if not user or not verify_password(password, user.password_hash):
        raise HTTPException(status_code=401, detail="E-mail ou senha inválidos")
    return issue_session(db, user)


def refresh(db: Session, raw_token: str) -> dict:
    session = (
        db.query(AuthSession)
        .filter(AuthSession.refresh_token_hash == token_hash(raw_token))
        .first()
    )
    if not session or session.revoked_at or session.expires_at <= datetime.utcnow():
        raise HTTPException(status_code=401, detail="Refresh token inválido ou expirado")
    session.revoked_at = datetime.utcnow()
    db.commit()
    return issue_session(db, session.user)


def logout(db: Session, raw_token: str) -> None:
    session = (
        db.query(AuthSession)
        .filter(AuthSession.refresh_token_hash == token_hash(raw_token))
        .first()
    )
    if session and not session.revoked_at:
        session.revoked_at = datetime.utcnow()
        db.commit()
