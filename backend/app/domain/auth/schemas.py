from datetime import date
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator
import re


def normalize_cep(value: str) -> str:
    if not re.fullmatch(r"\d{5}-?\d{3}", value.strip()):
        raise ValueError("CEP deve possuir oito dígitos")
    return value.replace("-", "")


class RegisterRequest(BaseModel):
    full_name: str = Field(min_length=1, max_length=150)
    nickname: str = Field(min_length=1, max_length=50)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    birth_date: date
    cep: str

    @field_validator("full_name", "nickname")
    @classmethod
    def non_blank(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("campo obrigatório")
        return value

    @field_validator("birth_date")
    @classmethod
    def past_birth_date(cls, value: date) -> date:
        if value >= date.today():
            raise ValueError("data de nascimento deve estar no passado")
        return value

    @field_validator("cep")
    @classmethod
    def valid_cep(cls, value: str) -> str:
        return normalize_cep(value)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class GoogleRequest(BaseModel):
    id_token: str = Field(min_length=1)


class GoogleCompleteRequest(BaseModel):
    onboarding_token: str
    nickname: str = Field(min_length=1, max_length=50)
    birth_date: date
    cep: str

    _nickname = field_validator("nickname")(RegisterRequest.non_blank.__func__)
    _birth = field_validator("birth_date")(RegisterRequest.past_birth_date.__func__)
    _cep = field_validator("cep")(RegisterRequest.valid_cep.__func__)


class RefreshRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str


class UserResponse(BaseModel):
    id: str
    full_name: str
    nickname: str
    email: EmailStr
    birth_date: date | None
    cep: str | None
    onboarding_complete: bool
    model_config = ConfigDict(from_attributes=True)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse


class GoogleOnboardingResponse(BaseModel):
    requires_onboarding: bool = True
    onboarding_token: str
    full_name: str
    email: EmailStr
