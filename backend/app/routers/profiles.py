from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Optional
from .. import models, schemas
from ..database import get_db
from ..auth import get_current_user
from ..utils import save_image
from ..models import Profile, User, Artwork

router = APIRouter(
    prefix="/profiles",
    tags=["profiles"]
)

# User Profile Endpoints
@router.get("/me", response_model=schemas.UserProfile)
async def get_my_profile(
    current_user: models.User = Depends(get_current_user)
):
    return current_user

@router.put("/me", response_model=schemas.UserProfile)
async def update_profile(
    bio: Optional[str] = Form(None),
    website: Optional[str] = Form(None),
    location: Optional[str] = Form(None),
    profile_picture: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if profile_picture:
        profile_picture_url = await save_image(profile_picture, "profiles")
        current_user.profile_picture = profile_picture_url
    
    if bio is not None:
        current_user.bio = bio
    if website is not None:
        current_user.website = website
    if location is not None:
        current_user.location = location
    
    db.commit()
    db.refresh(current_user)
    return current_user

@router.get("/{username}", response_model=schemas.UserProfile)
async def get_user_profile(
    username: str,
    db: Session = Depends(get_db)
):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user 

@router.get("/{user_id}/artworks", response_model=List[schemas.ArtworkResponse])
async def get_user_artworks(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(Artwork).filter(Artwork.artist_id == user_id)
    )
    return result.scalars().all() 