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
    try:
        print(f"Received request for artworks near lat:{latitude}, lon:{longitude}")
        
        # Get all artworks
        query = (
            select(models.Artwork)
            .filter(models.Artwork.status == "active")  # Only get active artworks
            .options(selectinload(models.Artwork.categories))  # Include categories
        )
        result = await db.execute(query)
        all_artworks = result.scalars().all()
        
        # Filter artworks by distance
        nearby_artworks = []
        for artwork in all_artworks:
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
                    "status": artwork.status,
                    "is_featured": artwork.is_featured,
                    "created_at": artwork.created_at.isoformat() if artwork.created_at else None,
                    "categories": [c.name for c in artwork.categories],
                    "distance": round(distance, 2)  # Include distance in km
                }
                nearby_artworks.append(artwork_dict)
        
        print(f"Found {len(nearby_artworks)} nearby artworks")
        return nearby_artworks
        
    except Exception as e:
        print(f"Error in get_nearby_artworks: {str(e)}")
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