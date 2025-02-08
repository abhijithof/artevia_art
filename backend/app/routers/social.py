from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from .. import models, schemas
from ..database import get_db
from ..auth import get_current_user
from ..models import Like, Comment, Artwork, User

router = APIRouter(tags=["social"])

# Likes
@router.post("/artworks/{artwork_id}/like", response_model=schemas.Like)
async def like_artwork(
    artwork_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    # Check if already liked
    existing_like = db.query(models.Like).filter(
        models.Like.user_id == current_user.id,
        models.Like.artwork_id == artwork_id
    ).first()
    
    if existing_like:
        raise HTTPException(status_code=400, detail="Already liked this artwork")
    
    like = models.Like(user_id=current_user.id, artwork_id=artwork_id)
    db.add(like)
    db.commit()
    db.refresh(like)
    return like

@router.delete("/artworks/{artwork_id}/like")
async def unlike_artwork(
    artwork_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    like = db.query(models.Like).filter(
        models.Like.user_id == current_user.id,
        models.Like.artwork_id == artwork_id
    ).first()
    
    if not like:
        raise HTTPException(status_code=404, detail="Like not found")
    
    db.delete(like)
    db.commit()
    return {"message": "Artwork unliked"}

# Comments
@router.post("/artworks/{artwork_id}/comments", response_model=schemas.Comment)
async def create_comment(
    artwork_id: int,
    comment: schemas.CommentCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    db_comment = models.Comment(
        text=comment.text,
        user_id=current_user.id,
        artwork_id=artwork_id
    )
    db.add(db_comment)
    db.commit()
    db.refresh(db_comment)
    return db_comment

@router.get("/artworks/{artwork_id}/comments", response_model=List[schemas.Comment])
async def get_artwork_comments(
    artwork_id: int,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    comments = db.query(models.Comment).filter(
        models.Comment.artwork_id == artwork_id
    ).offset(skip).limit(limit).all()
    return comments

@router.get("/likes", response_model=List[schemas.ArtworkResponse])
async def get_liked_artworks(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(Artwork)
        .join(Like)
        .filter(Like.user_id == current_user.id)
    )
    return result.scalars().all() 