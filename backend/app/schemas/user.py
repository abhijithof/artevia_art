from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: str
    username: str
    role: Optional[str] = "user"

class UserCreate(UserBase):
    password: str

class UserUpdate(UserBase):
    password: Optional[str] = None
    bio: Optional[str] = None
    website: Optional[str] = None
    location: Optional[str] = None
    social_links: Optional[str] = None

class UserInDB(UserBase):
    id: int
    hashed_password: str
    is_active: bool = True
    status: str = "active"

class UserProfile(BaseModel):
    id: int
    username: str
    email: str
    bio: Optional[str] = None
    website: Optional[str] = None
    location: Optional[str] = None
    social_links: Optional[str] = None
    profile_picture: Optional[str] = None
    role: str
    status: str
    created_at: Optional[datetime] = None

class User(UserBase):
    id: int
    is_active: bool = True
    status: str = "active"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    profile_picture: Optional[str] = None
    bio: Optional[str] = None
    website: Optional[str] = None
    location: Optional[str] = None
    social_links: Optional[str] = None

    class Config:
        from_attributes = True 