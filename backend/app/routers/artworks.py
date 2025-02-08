from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Query, BackgroundTasks, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from .. import models, schemas
from ..database import get_db
from ..auth import get_current_user
from ..utils import save_image, calculate_distance, PaginationParams, search_filter
from PIL import Image
import io
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from ..schemas.pagination import Page
from sqlalchemy.orm import selectinload

router = APIRouter(
    prefix="/artworks",
    tags=["artworks"]
)

# First, endpoint to get categories for the dropdown
@router.get("/categories", response_model=List[schemas.Category])
async def get_categories(db: Session = Depends(get_db)):
    """Get all available categories for artwork creation"""
    return db.query(models.Category).all()

# CRUD Operations
@router.post("/", response_model=schemas.ArtworkResponse)
async def create_artwork(
    title: str = Form(...),
    description: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    category_id: int = Form(...),  # Single category selection
    image: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role != "artist":
        raise HTTPException(status_code=403, detail="Only artists can create artworks")
    
    # Verify category exists
    category = db.query(models.Category).filter(models.Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    # Validate image
    allowed_types = {"image/jpeg", "image/png", "image/webp"}
    if image.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="Invalid image type")
    
    # Save and process image
    image_url = await save_image(image)
    
    db_artwork = models.Artwork(
        title=title,
        description=description,
        image_url=image_url,
        latitude=latitude,
        longitude=longitude,
        artist_id=current_user.id,
        categories=[category]  # Assign the selected category
    )
    
    db.add(db_artwork)
    db.commit()
    db.refresh(db_artwork)
    return schemas.ArtworkResponse(
        id=db_artwork.id,
        title=db_artwork.title,
        description=db_artwork.description,
        image_url=db_artwork.image_url,
        latitude=db_artwork.latitude,
        longitude=db_artwork.longitude,
        artist_id=db_artwork.artist_id,
        status=db_artwork.status,
        is_featured=db_artwork.is_featured,
        created_at=db_artwork.created_at,
        categories=[c.name for c in db_artwork.categories]
    )

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
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    artwork = db.query(models.Artwork).filter(models.Artwork.id == artwork_id).first()
    if not artwork:
        raise HTTPException(status_code=404, detail="Artwork not found")
    if artwork.artist_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this artwork")
    
    db.delete(artwork)
    db.commit()

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
    # Use selectinload to load categories relationship
    query = select(models.Artwork).options(selectinload(models.Artwork.categories))
    result = await db.execute(query)
    artworks = result.scalars().all()
    
    # Filter artworks within radius
    nearby_artworks = [
        artwork for artwork in artworks
        if calculate_distance(latitude, longitude, artwork.latitude, artwork.longitude) <= radius
    ]
    
    # Return with all fields intact
    return [
        {
            "id": artwork.id,
            "title": artwork.title,
            "description": artwork.description,
            "image_url": artwork.image_url,
            "latitude": artwork.latitude,
            "longitude": artwork.longitude,
            "artist_id": artwork.artist_id,
            "status": artwork.status,
            "is_featured": artwork.is_featured,
            "created_at": artwork.created_at,
            "categories": [c.name for c in artwork.categories]
        }
        for artwork in nearby_artworks
    ]

@router.get("/", response_model=List[schemas.ArtworkResponse])
async def get_artworks(
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    try:
        # Use selectinload to load categories relationship
        stmt = select(models.Artwork).options(selectinload(models.Artwork.categories))
        result = await db.execute(stmt)
        artworks = result.scalars().all()
        
        # Convert to response model
        artwork_responses = []
        for artwork in artworks:
            artwork_responses.append(
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
            )
        return artwork_responses

    except Exception as e:
        print(f"Error fetching artworks: {e}")
        raise HTTPException(status_code=500, detail=str(e))

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