from datetime import datetime, timedelta
from fastapi import HTTPException
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.settings import settings
from app.domain.auth.schemas import RegisterRequest, UserResponse
from app.domain.auth.security import decode_token, encode_token, hash_password, new_refresh_token, token_hash, verify_password
from app.domain.users.models import AuthSession, User


def normalized(value: str) -> str:
    return value.strip().casefold()


def user_response(user: User) -> UserResponse:
    return UserResponse(id=user.id, full_name=user.full_name, nickname=user.username,
                        email=user.email, birth_date=user.birth_date, cep=user.cep,
                        onboarding_complete=user.onboarding_complete)


def _conflict(db: Session, email: str, nickname: str) -> None:
    if db.query(User).filter(User.email_normalized == normalized(email)).first():
        raise HTTPException(status_code=409, detail="E-mail já cadastrado")
    if db.query(User).filter(User.username_normalized == normalized(nickname)).first():
        raise HTTPException(status_code=409, detail="Nickname já utilizado")


def issue_session(db: Session, user: User) -> dict:
    refresh = new_refresh_token()
    session = AuthSession(user_id=user.id, refresh_token_hash=token_hash(refresh),
                          expires_at=datetime.utcnow() + timedelta(days=settings.refresh_token_days))
    db.add(session)
    db.commit()
    return {"access_token": encode_token(user.id, "access", timedelta(minutes=settings.access_token_minutes)),
            "refresh_token": refresh, "token_type": "bearer", "user": user_response(user)}


def register(db: Session, body: RegisterRequest) -> dict:
    _conflict(db, str(body.email), body.nickname)
    user = User(username=body.nickname, username_normalized=normalized(body.nickname),
                email=str(body.email).lower(), email_normalized=normalized(str(body.email)),
                full_name=body.full_name, cep=body.cep, birth_date=body.birth_date,
                password_hash=hash_password(body.password), onboarding_complete=True)
    db.add(user)
    try:
        db.flush()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="E-mail ou nickname já cadastrado")
    return issue_session(db, user)


def login(db: Session, email: str, password: str) -> dict:
    user = db.query(User).filter(User.email_normalized == normalized(email)).first()
    if not user or not user.onboarding_complete or not verify_password(password, user.password_hash):
        raise HTTPException(status_code=401, detail="E-mail ou senha inválidos")
    return issue_session(db, user)


def refresh(db: Session, raw_token: str) -> dict:
    session = db.query(AuthSession).filter(AuthSession.refresh_token_hash == token_hash(raw_token)).first()
    if not session or session.revoked_at or session.expires_at <= datetime.utcnow():
        raise HTTPException(status_code=401, detail="Refresh token inválido ou expirado")
    session.revoked_at = datetime.utcnow()
    db.commit()
    return issue_session(db, session.user)


def logout(db: Session, raw_token: str) -> None:
    session = db.query(AuthSession).filter(AuthSession.refresh_token_hash == token_hash(raw_token)).first()
    if session and not session.revoked_at:
        session.revoked_at = datetime.utcnow()
        db.commit()


def verify_google(raw_token: str) -> dict:
    if not settings.google_client_id:
        raise HTTPException(status_code=503, detail="Login Google não configurado")
    try:
        payload = google_id_token.verify_oauth2_token(raw_token, google_requests.Request(), settings.google_client_id)
    except ValueError:
        raise HTTPException(status_code=401, detail="Token Google inválido")
    if not payload.get("email_verified") or not payload.get("sub") or not payload.get("email"):
        raise HTTPException(status_code=401, detail="Conta Google sem e-mail verificado")
    return payload


def google_login(db: Session, raw_token: str) -> dict:
    payload = verify_google(raw_token)
    user = db.query(User).filter(User.google_subject == payload["sub"]).first()
    if not user:
        user = db.query(User).filter(User.email_normalized == normalized(payload["email"])).first()
    if user:
        if user.google_subject and user.google_subject != payload["sub"]:
            raise HTTPException(status_code=409, detail="E-mail vinculado a outra conta Google")
        user.google_subject = payload["sub"]
        db.commit()
        if user.onboarding_complete:
            return issue_session(db, user)
    else:
        user = User(full_name=payload.get("name") or payload["email"], email=payload["email"].lower(),
                    email_normalized=normalized(payload["email"]), google_subject=payload["sub"],
                    onboarding_complete=False)
        db.add(user)
        db.commit()
        db.refresh(user)
    return {"requires_onboarding": True,
            "onboarding_token": encode_token(user.id, "onboarding", timedelta(minutes=settings.onboarding_token_minutes)),
            "full_name": user.full_name, "email": user.email}


def complete_google(db: Session, onboarding_token: str, nickname: str, birth_date, cep: str) -> dict:
    payload = decode_token(onboarding_token, "onboarding")
    user = db.get(User, payload["sub"])
    if not user or user.onboarding_complete or not user.google_subject:
        raise HTTPException(status_code=401, detail="Onboarding inválido ou já concluído")
    if db.query(User).filter(User.username_normalized == normalized(nickname), User.id != user.id).first():
        raise HTTPException(status_code=409, detail="Nickname já utilizado")
    user.username = nickname
    user.username_normalized = normalized(nickname)
    user.birth_date = birth_date
    user.cep = cep
    user.onboarding_complete = True
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Nickname já utilizado")
    return issue_session(db, user)
