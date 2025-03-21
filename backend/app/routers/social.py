from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import List
from .. import models, schemas
from ..database import get_db
from ..auth import get_current_user
from ..models import Like, Comment, Artwork, User

router = APIRouter(tags=["social"])

# Likes
@router.post("/artworks/{artwork_id}/like")
async def like_artwork(
    artwork_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(models.Like).where(
        models.Like.artwork_id == artwork_id,
        models.Like.user_id == current_user.id
    )
    result = await db.execute(query)
    existing_like = result.scalar_one_or_none()

    if not existing_like:
        new_like = models.Like(
            artwork_id=artwork_id,
            user_id=current_user.id
        )
        db.add(new_like)
        await db.commit()
        return {"message": "Artwork liked successfully"}
    
    return {"message": "Already liked"}

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
@router.post("/artworks/{artwork_id}/comments")
async def create_comment(
    artwork_id: int,
    comment: schemas.CommentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_comment = models.Comment(
        text=comment.text,
        user_id=current_user.id,
        artwork_id=artwork_id
    )
    db.add(db_comment)
    await db.commit()
    await db.refresh(db_comment)
    
    # Include username in response
    return {
        "id": db_comment.id,
        "text": db_comment.text,
        "user_id": db_comment.user_id,
        "artwork_id": db_comment.artwork_id,
        "created_at": db_comment.created_at,
        "username": current_user.username  # Add username here
    }

@router.get("/artworks/{artwork_id}/comments")
async def get_artwork_comments(
    artwork_id: int,
    db: AsyncSession = Depends(get_db)
):
    query = (
        select(models.Comment, models.User.username)
        .join(models.User, models.Comment.user_id == models.User.id)
        .where(models.Comment.artwork_id == artwork_id)
    )
    result = await db.execute(query)
    comments = result.all()
    
    return [
        {
            "id": comment[0].id,
            "text": comment[0].text,
            "user_id": comment[0].user_id,
            "artwork_id": comment[0].artwork_id,
            "created_at": comment[0].created_at,
            "username": comment[1]
        }
        for comment in comments
    ]

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

@router.get("/artworks/{artwork_id}/likes/count")
async def get_artwork_like_count(
    artwork_id: int,
    db: AsyncSession = Depends(get_db)
):
    query = select(func.count(models.Like.id)).where(
        models.Like.artwork_id == artwork_id
    )
    result = await db.execute(query)
    count = result.scalar()
    return {"count": count} 