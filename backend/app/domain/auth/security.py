from datetime import datetime, timedelta
import hashlib
import secrets
import jwt
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerifyMismatchError
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.settings import settings
from app.domain.users.models import User

hasher = PasswordHasher()
bearer = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    return hasher.hash(password)


def verify_password(password: str, password_hash: str | None) -> bool:
    if not password_hash:
        return False
    try:
        return hasher.verify(password_hash, password)
    except (VerifyMismatchError, InvalidHashError):
        return False


def encode_token(subject: str, token_type: str, expires: timedelta, **claims) -> str:
    now = datetime.utcnow()
    return jwt.encode({"sub": subject, "type": token_type, "iat": now, "exp": now + expires, **claims}, settings.jwt_secret, algorithm="HS256")


def decode_token(token: str, expected_type: str) -> dict:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=["HS256"])
        if payload.get("type") != expected_type:
            raise ValueError
        return payload
    except (jwt.PyJWTError, ValueError):
        raise HTTPException(status_code=401, detail="Sessão inválida ou expirada")


def new_refresh_token() -> str:
    return secrets.token_urlsafe(48)


def token_hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def get_current_user(credentials: HTTPAuthorizationCredentials | None = Depends(bearer), db: Session = Depends(get_db)) -> User:
    if credentials is None:
        raise HTTPException(status_code=401, detail="Autenticação necessária")
    payload = decode_token(credentials.credentials, "access")
    user = db.get(User, payload["sub"])
    if not user:
        raise HTTPException(status_code=401, detail="Sessão inválida ou expirada")
    return user
