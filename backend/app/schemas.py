from pydantic import BaseModel, EmailStr, HttpUrl, constr
from typing import Optional, List, Dict
from datetime import datetime

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

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    email: Optional[str] = None
    username: Optional[str] = None
    password: Optional[str] = None

class User(UserBase):
    id: int
    role: str

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
class ArtworkBase(BaseModel):
    title: str
    description: Optional[str] = None
    latitude: float
    longitude: float

class ArtworkCreate(ArtworkBase):
    pass

class Artwork(ArtworkBase):
    id: int
    image_url: str
    artist_id: int
    status: str
    is_featured: bool
    created_at: datetime
    artist: User
    categories: List[Category] = []
    likes: List[Like] = []
    comments: List[Comment] = []

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
