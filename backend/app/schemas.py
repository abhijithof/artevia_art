from pydantic import BaseModel, EmailStr, HttpUrl, constr
from typing import Optional, List, Dict
from datetime import datetime
from fastapi import UploadFile

# Category Schemas
class CategoryBase(BaseModel):
    name: str
    description: Optional[str] = None

class CategoryCreate(CategoryBase):
    pass

class Category(CategoryBase):
    id: int

    class Config:
        from_attributes = True

# User Schemas
class UserBase(BaseModel):
    email: str
    username: str
    role: Optional[str] = "user"

class UserCreate(UserBase):
    password: str

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

# Comment Schemas
class CommentBase(BaseModel):
    text: str

class CommentCreate(CommentBase):
    pass

class Comment(CommentBase):
    id: int
    user_id: int
    artwork_id: int
    created_at: datetime
    user: User

    class Config:
        from_attributes = True

# Like Schema
class Like(BaseModel):
    id: int
    user_id: int
    artwork_id: int
    created_at: datetime

    class Config:
        from_attributes = True

# Discovery Schema
class Discovery(BaseModel):
    id: int
    user_id: int
    artwork_id: int
    discovered_at: datetime

    class Config:
        from_attributes = True

# Artwork Schemas
class artwork(BaseModel):
    title: str
    description: str
    latitude: float
    longitude: float
    status: str = "active"
    is_featured: bool = False
    image_url: Optional[str] = None

class ArtworkCreate(artwork):
    pass

class Artwork(artwork):
    id: int
    artist_id: int
    created_at: datetime

    class Config:
        from_attributes = True

# Token Schema
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

# User Profile Schemas
class UserProfileBase(BaseModel):
    username: str
    email: EmailStr
    role: str
    status: str
    bio: Optional[str] = None
    website: Optional[str] = None
    location: Optional[str] = None
    profile_picture: Optional[str] = None
    social_links: Dict[str, str] = {}

class UserProfile(UserProfileBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class UserProfileUpdate(BaseModel):
    bio: Optional[str] = None
    website: Optional[str] = None
    location: Optional[str] = None
    social_links: Optional[Dict[str, str]] = None

# Admin Stats Schema
class AdminStats(BaseModel):
    total_users: int
    total_artists: int
    total_artworks: int
    total_likes: int
    total_comments: int

# Moderation Log Schema
class ModerationLog(BaseModel):
    id: int
    admin_id: int
    action: str
    target_type: str
    target_id: int
    reason: str
    created_at: datetime

    class Config:
        from_attributes = True
