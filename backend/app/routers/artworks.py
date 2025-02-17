from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Query, BackgroundTasks, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from .. import models, schemas
from ..database import get_db
from ..auth.auth import get_current_user
from ..utils import save_image, calculate_distance, PaginationParams, search_filter, save_uploaded_file
from PIL import Image
import io
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from ..schemas.pagination import Page
from sqlalchemy.orm import selectinload
from ..schemas.artwork import Artwork, ArtworkCreate, ArtworkResponse
from datetime import datetime

router = APIRouter(
    prefix="/artworks",
    tags=["artworks"]
)

# Predefined categories
PREDEFINED_CATEGORIES = [
    "Mural",
    "Graffiti",
    "Sculpture",
    "Installation",
    "Street Art",
    "Digital Art",
    "Mixed Media",
    "Traditional",
]

# First, endpoint to get categories for the dropdown
@router.get("/categories")
async def get_categories(db: AsyncSession = Depends(get_db)):
    try:
        # For now, just return predefined categories
        return PREDEFINED_CATEGORIES
    except Exception as e:
        print(f"Error getting categories: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# CRUD Operations
@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_artwork(
    title: str = Form(...),
    description: str = Form(...),
    image: UploadFile = File(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    category: str = Form(...),
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    try:
        # Save the image
        image_path = await save_uploaded_file(image)
        
        # Create artwork
        artwork = models.Artwork(
            title=title,
            description=description,
            image_url=image_path,
            latitude=latitude,
            longitude=longitude,
            artist_id=current_user.id,
            status="active"
        )
        
        db.add(artwork)
        await db.commit()
        await db.refresh(artwork)
        
        return {
            "id": artwork.id,
            "title": artwork.title,
            "description": artwork.description,
            "image_url": artwork.image_url,
            "latitude": artwork.latitude,
            "longitude": artwork.longitude,
            "artist_id": artwork.artist_id,
            "status": artwork.status
        }
    except Exception as e:
        print(f"Error creating artwork: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/{artwork_id}", response_model=schemas.ArtworkResponse)
async def update_artwork(
    artwork_id: int,
    title: str = None,
    description: str = None,
    image: UploadFile = File(None),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    artwork = db.query(models.Artwork).filter(models.Artwork.id == artwork_id).first()
    if not artwork:
        raise HTTPException(status_code=404, detail="Artwork not found")
    if artwork.artist_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this artwork")
    
    if title:
        artwork.title = title
    if description:
        artwork.description = description
    if image:
        artwork.image_url = await save_image(image)
    
    db.commit()
    db.refresh(artwork)
    return schemas.ArtworkResponse(
        id=artwork.id,
        title=artwork.title,
        description=artwork.description,
        image_url=artwork.image_url,
        latitude=artwork.latitude,
        longitude=artwork.longitude,
        artist_id=artwork.artist_id,
        status=artwork.status,
        is_featured=artwork.is_featured,
        created_at=artwork.created_at,
        categories=[c.name for c in artwork.categories]
    )

@router.delete("/{artwork_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_artwork(
    artwork_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    try:
        # Use async query to get the artwork
        query = select(models.Artwork).where(models.Artwork.id == artwork_id)
        result = await db.execute(query)
        artwork = result.scalar_one_or_none()

        if not artwork:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Artwork not found"
            )

        # Check if the current user is the owner
        if artwork.artist_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete this artwork"
            )

        # Delete the artwork
        await db.delete(artwork)
        await db.commit()

        return {"message": "Artwork deleted successfully"}

    except Exception as e:
        await db.rollback()
        print(f"Error deleting artwork: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

# Category Operations
@router.post("/{artwork_id}/categories")
async def add_categories(
    artwork_id: int,
    category_ids: List[int],
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    artwork = db.query(models.Artwork).filter(models.Artwork.id == artwork_id).first()
    if not artwork:
        raise HTTPException(status_code=404, detail="Artwork not found")
    if artwork.artist_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    categories = db.query(models.Category).filter(models.Category.id.in_(category_ids)).all()
    artwork.categories.extend(categories)
    db.commit()
    return {"message": "Categories added successfully"}

# Featured Artworks
@router.get("/featured", response_model=List[schemas.ArtworkResponse])
async def get_featured_artworks(
    skip: int = 0,
    limit: int = 10,
    db: Session = Depends(get_db)
):
    artworks = db.query(models.Artwork).filter(
        models.Artwork.is_featured == True
    ).offset(skip).limit(limit).all()
    return [schemas.ArtworkResponse(
        id=artwork.id,
        title=artwork.title,
        description=artwork.description,
        image_url=artwork.image_url,
        latitude=artwork.latitude,
        longitude=artwork.longitude,
        artist_id=artwork.artist_id,
        status=artwork.status,
        is_featured=artwork.is_featured,
        created_at=artwork.created_at,
        categories=[c.name for c in artwork.categories]
    ) for artwork in artworks]

# Nearby Artworks
@router.get("/nearby")
async def get_nearby_artworks(
    latitude: float,
    longitude: float,
    radius: float = 5.0,
    db: AsyncSession = Depends(get_db)
):
    try:
        print(f"Received request for artworks near lat:{latitude}, lon:{longitude}")
        
        # Get all artworks with artist information
        query = (
            select(models.Artwork, models.User.username.label('artist_name'))
            .join(models.User, models.Artwork.artist_id == models.User.id)
            .filter(models.Artwork.status == "active")
            .options(selectinload(models.Artwork.categories))
        )
        result = await db.execute(query)
        all_artworks = result.all()
        
        # Filter artworks by distance
        nearby_artworks = []
        for artwork_row in all_artworks:
            artwork = artwork_row[0]
            artist_name = artwork_row[1]
            distance = calculate_distance(
                latitude, longitude,
                artwork.latitude, artwork.longitude
            )
            if distance <= radius:
                artwork_dict = {
                    "id": artwork.id,
                    "title": artwork.title,
                    "description": artwork.description,
                    "image_url": artwork.image_url,
                    "latitude": artwork.latitude,
                    "longitude": artwork.longitude,
                    "artist_id": artwork.artist_id,
                    "artist_name": artist_name,  # Include artist name
                    "status": artwork.status,
                    "is_featured": artwork.is_featured,
                    "created_at": artwork.created_at,
                    "categories": [c.name for c in artwork.categories],
                    "distance": distance / 1000  # Convert to kilometers
                }
                nearby_artworks.append(artwork_dict)
        
        return nearby_artworks
    except Exception as e:
        print(f"Error in get_nearby_artworks: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[ArtworkResponse])
async def get_artworks(
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    stmt = select(models.Artwork).options(selectinload(models.Artwork.categories))
    result = await db.execute(stmt)
    artworks = result.scalars().all()
    
    return [
        ArtworkResponse(
            id=artwork.id,
            title=artwork.title,
            description=artwork.description,
            image_url=artwork.image_url,
            latitude=artwork.latitude,
            longitude=artwork.longitude,
            artist_id=artwork.artist_id,
            status=artwork.status,
            is_featured=artwork.is_featured,
            created_at=artwork.created_at,
            categories=[c.name for c in artwork.categories]
        )
        for artwork in artworks
    ]

@router.get("/{artwork_id}", response_model=schemas.ArtworkResponse)
async def get_artwork(
    artwork_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    result = await db.execute(select(models.Artwork).filter(models.Artwork.id == artwork_id))
    artwork = result.scalar_one_or_none()
    
    if artwork is None:
        raise HTTPException(status_code=404, detail="Artwork not found")
        
    return schemas.ArtworkResponse(
        id=artwork.id,
        title=artwork.title,
        description=artwork.description,
        image_url=artwork.image_url,
        latitude=artwork.latitude,
        longitude=artwork.longitude,
        artist_id=artwork.artist_id,
        status=artwork.status,
        is_featured=artwork.is_featured,
        created_at=artwork.created_at,
        categories=[c.name for c in artwork.categories]
    )

async def process_image(image_path: str):
    """Process image in background"""
    with Image.open(image_path) as img:
        # Resize if too large
        if img.size[0] > 1920 or img.size[1] > 1080:
            img.thumbnail((1920, 1080))
        
        # Optimize and save
        img.save(image_path, optimize=True, quality=85)

@router.post("/unlock", status_code=status.HTTP_200_OK)
async def unlock_artwork(
    artwork_data: schemas.UnlockedArtworkCreate,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    try:
        # Check if artwork exists
        artwork_query = select(models.Artwork).where(models.Artwork.id == artwork_data.artwork_id)
        result = await db.execute(artwork_query)
        artwork = result.scalar_one_or_none()
        
        if not artwork:
            raise HTTPException(status_code=404, detail="Artwork not found")

        # Check if already unlocked
        unlocked_query = select(models.UnlockedArtwork).where(
            models.UnlockedArtwork.user_id == current_user.id,
            models.UnlockedArtwork.artwork_id == artwork_data.artwork_id
        )
        result = await db.execute(unlocked_query)
        existing_unlock = result.scalar_one_or_none()
        
        if existing_unlock:
            return {"message": "Artwork already unlocked"}

        # Create new unlock record
        new_unlock = models.UnlockedArtwork(
            user_id=current_user.id,
            artwork_id=artwork_data.artwork_id
        )
        db.add(new_unlock)
        await db.commit()
        
        return {"message": "Artwork unlocked successfully"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/unlocked", response_model=List[schemas.ArtworkResponse])
async def get_unlocked_artworks(
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    try:
        # Get all unlocked artworks for the current user
        query = (
            select(models.Artwork)
            .join(models.UnlockedArtwork)
            .where(models.UnlockedArtwork.user_id == current_user.id)
            .options(selectinload(models.Artwork.categories))
        )
        result = await db.execute(query)
        artworks = result.scalars().all()
        
        return [
            schemas.ArtworkResponse(
                id=artwork.id,
                title=artwork.title,
                description=artwork.description,
                image_url=artwork.image_url,
                latitude=artwork.latitude,
                longitude=artwork.longitude,
                artist_id=artwork.artist_id,
                status=artwork.status,
                is_featured=artwork.is_featured,
                created_at=artwork.created_at,
                categories=[c.name for c in artwork.categories]
            )
            for artwork in artworks
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 