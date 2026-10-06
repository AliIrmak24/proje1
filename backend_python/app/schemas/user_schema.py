# app/schemas/user_schema.py
# User ve Arkadaşlık verileri için Pydantic şemaları

from datetime import datetime
from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str

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
    created_at: datetime

    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    username: str | None = None
    bio: str | None = None
    full_name: str | None = None
    email: EmailStr | None = None
    phone_number: str | None = None
    avatar_url: str | None = None
    language: str | None = None

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str

class UserLogin(BaseModel):
    username: str | None = None
    email: EmailStr | None = None
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse | None = None

class FriendUserSummary(BaseModel):
    id: int
    username: str
    level: int
    xp: int
    bio: str | None = None

class FriendResponse(BaseModel):
    friendship_id: int
    friend: FriendUserSummary
    status: str
    created_at: datetime

class FriendRequestCreate(BaseModel):
    target_username: str
