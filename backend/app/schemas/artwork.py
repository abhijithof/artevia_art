from datetime import datetime
from pydantic import BaseModel
from typing import List, Optional

class ArtworkBase(BaseModel):
    title: str
    description: str
    image_url: str
    latitude: float
    longitude: float
    status: str = "active"
    is_featured: bool = False
    categories: List[str] = []

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
    categories: Optional[List[str]] = None

class ArtworkResponse(ArtworkBase):
    id: int
    artist_id: int
    created_at: datetime

    class Config:
        from_attributes = True 