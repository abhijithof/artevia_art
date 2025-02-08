from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, Dict

class UserBase(BaseModel):
    username: str
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = None

class User(UserBase):
    id: int
    role: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class UserInDB(User):
    password_hash: str

class UserProfile(User):
    profile: Optional[Dict] = None
    total_artworks: int = 0
    total_discoveries: int = 0

    class Config:
        from_attributes = True 