from datetime import datetime
from pydantic import BaseModel
from typing import List, Optional

class ArtworkBase(BaseModel):
    title: str
    description: str
    latitude: float
    longitude: float
    status: str = "active"
    is_featured: bool = False
    image_url: Optional[str] = None

class ArtworkCreate(ArtworkBase):
    pass

class ArtworkUpdate(ArtworkBase):
    title: Optional[str] = None
    description: Optional[str] = None
    image_url: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    status: Optional[str] = None
    is_featured: Optional[bool] = None

class Artwork(ArtworkBase):
    id: int
    artist_id: int
    created_at: datetime

    class Config:
        from_attributes = True

class ArtworkResponse(Artwork):
    categories: List[str] = []

class UnlockedArtworkCreate(BaseModel):
    artwork_id: int

class UnlockedArtwork(BaseModel):
    id: int
    user_id: int
    artwork_id: int
    unlocked_at: datetime

    class Config:
        from_attributes = True 