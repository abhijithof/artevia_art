from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from .. import schemas
from ..database import get_db
from ..models import Discovery, Artwork, User
from ..auth import get_current_user

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