from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from .. import schemas
from ..database import get_db
from ..models import Discovery, Artwork, User
from ..auth import get_current_user
from ..utils import calculate_distance

router = APIRouter(
    prefix="/discoveries",
    tags=["discoveries"]
)

@router.post("/{artwork_id}", response_model=schemas.Discovery)
async def create_discovery(
    artwork_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Check if artwork exists
    result = await db.execute(select(Artwork).filter(Artwork.id == artwork_id))
    artwork = result.scalar_one_or_none()
    if not artwork:
        raise HTTPException(status_code=404, detail="Artwork not found")

    # Create discovery
    discovery = Discovery(user_id=current_user.id, artwork_id=artwork_id)
    db.add(discovery)
    await db.commit()
    await db.refresh(discovery)
    return discovery

@router.get("/my", response_model=List[schemas.ArtworkResponse])
async def get_my_discoveries(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(Artwork)
        .join(Discovery)
        .filter(Discovery.user_id == current_user.id)
    )
    return result.scalars().all()

@router.post("/artworks/{artwork_id}/unlock")
async def unlock_artwork(
    artwork_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Check if artwork exists
    result = await db.execute(select(Artwork).filter(Artwork.id == artwork_id))
    artwork = result.scalar_one_or_none()
    if not artwork:
        raise HTTPException(status_code=404, detail="Artwork not found")

    # Check if already unlocked
    discovery_result = await db.execute(
        select(Discovery).filter(
            Discovery.artwork_id == artwork_id,
            Discovery.user_id == current_user.id
        )
    )
    existing_discovery = discovery_result.scalar_one_or_none()
    if existing_discovery:
        raise HTTPException(status_code=400, detail="Artwork already unlocked")

    # Calculate distance between user and artwork
    # You'll need to pass user's current location in the request
    user_lat = float(request.query_params.get('latitude'))
    user_lng = float(request.query_params.get('longitude'))
    
    distance = calculate_distance(
        user_lat, user_lng,
        artwork.latitude, artwork.longitude
    )

    # Check if user is within 1km
    if distance > 1.0:  # 1.0 km
        raise HTTPException(
            status_code=400, 
            detail=f"Too far from artwork. Must be within 1km. Current distance: {distance:.2f}km"
        )

    # Create discovery record
    discovery = Discovery(
        user_id=current_user.id,
        artwork_id=artwork_id
    )
    db.add(discovery)
    await db.commit()
    await db.refresh(discovery)

    return {
        "message": "Artwork unlocked successfully",
        "discovery_id": discovery.id,
        "artwork": {
            "id": artwork.id,
            "title": artwork.title,
            "description": artwork.description,
            "image_url": artwork.image_url,
            "latitude": artwork.latitude,
            "longitude": artwork.longitude,
            "artist_id": artwork.artist_id,
            "created_at": artwork.created_at
        }
    } 