# app/schemas/user_schema.py
# User ve Arkadaşlık verileri için Pydantic şemaları

import re
from datetime import datetime
from typing import Annotated, Literal
from pydantic import AfterValidator, BaseModel, EmailStr, Field

USERNAME_PATTERN = re.compile(r"^[\w.-]{3,30}$")

def _validate_username(value: str) -> str:
    value = value.strip()
    if not USERNAME_PATTERN.match(value):
        raise ValueError("Kullanıcı adı 3-30 karakter olmalı; harf, rakam, nokta, tire ve alt çizgi içerebilir")
    return value

def _validate_password(value: str) -> str:
    if len(value) < 8:
        raise ValueError("Şifre en az 8 karakter olmalıdır")
    if len(value.encode("utf-8")) > 72:
        raise ValueError("Şifre en fazla 72 bayt olabilir")
    return value

Username = Annotated[str, AfterValidator(_validate_username)]
Password = Annotated[str, AfterValidator(_validate_password)]
CefrLevel = Literal["A1", "A2", "B1", "B2", "C1", "C2"]

class UserCreate(BaseModel):
    username: Username
    email: EmailStr
    password: Password

class UserResponse(BaseModel):
    id: int
    username: str
    email: EmailStr
    xp: int
    level: int
    bio: str | None = None
    full_name: str | None = None
    phone_number: str | None = None
    avatar_url: str | None = None
    language: str | None = "tr"
    cefr_level: str | None = None
    created_at: datetime

    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    username: Username | None = None
    bio: str | None = Field(default=None, max_length=300)
    full_name: str | None = Field(default=None, max_length=100)
    email: EmailStr | None = None
    phone_number: str | None = Field(default=None, max_length=30)
    avatar_url: str | None = Field(default=None, max_length=500)
    language: str | None = Field(default=None, max_length=10)
    cefr_level: CefrLevel | None = None

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: Password

class DeleteAccountRequest(BaseModel):
    password: str

class UserLogin(BaseModel):
    username: str | None = None
    email: EmailStr | None = None
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse | None = None

class FriendRequestCreate(BaseModel):
    target_username: str
