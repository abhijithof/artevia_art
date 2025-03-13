from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from .. import models, schemas
from ..database import get_db
from ..auth import get_current_user
from ..models import Category, Artwork, User

router = APIRouter(
    prefix="/categories",
    tags=["categories"]
)

@router.post("/", response_model=schemas.Category)
async def create_category(
    category: schemas.CategoryCreate,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only admins can create categories")
    
    # Check if category already exists
    result = await db.execute(
        select(Category).where(Category.name == category.name)
    )
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Category already exists")
    
    db_category = Category(**category.dict())
    db.add(db_category)
    await db.commit()
    await db.refresh(db_category)
    return db_category

@router.get("/", response_model=List[schemas.Category])
async def get_categories(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Category)
        .order_by(Category.name)
    )
    categories = result.scalars().all()
    return categories

@router.put("/{category_id}", response_model=schemas.Category)
async def update_category(
    category_id: int,
    category: schemas.CategoryCreate,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only admins can update categories")
    
    result = await db.execute(
        select(Category).where(Category.id == category_id)
    )
    db_category = result.scalar_one_or_none()
    
    if not db_category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    db_category.name = category.name
    db_category.description = category.description
    await db.commit()
    await db.refresh(db_category)
    return db_category

@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    category_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only admins can delete categories")
        
    result = await db.execute(
        select(Category).where(Category.id == category_id)
    )
    category = result.scalar_one_or_none()
    
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    await db.delete(category)
    await db.commit()

@router.get("/{category_id}/artworks", response_model=List[schemas.ArtworkResponse])
async def get_artworks_by_category(
    category_id: int,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Artwork)
        .join(Artwork.categories)
        .filter(Category.id == category_id)
    )
    return result.scalars().all() 