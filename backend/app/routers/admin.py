from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from .. import models, schemas
from ..database import get_db
from ..auth import get_current_user
from datetime import datetime

router = APIRouter(
    prefix="/admin",
    tags=["admin"]
)

async def get_current_admin(
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(
            status_code=403,
            detail="Only admins can access this resource"
        )
    return current_user

# User Management
@router.get("/users", response_model=List[schemas.UserProfile])
async def list_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    users = db.query(models.User).offset(skip).limit(limit).all()
    return users

@router.put("/users/{user_id}/status")
async def update_user_status(
    user_id: int,
    status: str,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.status = status
    db.commit()
    return {"message": f"User status updated to {status}"}

# Enhanced User Management
@router.put("/users/{user_id}/ban")
async def ban_user(
    user_id: int,
    reason: str,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.role == "admin":
        raise HTTPException(status_code=400, detail="Cannot ban admin users")
    
    user.status = "banned"
    user.ban_reason = reason
    
    # Log the action
    await log_moderation(
        db=db,
        admin_id=admin.id,
        action="ban_user",
        target_type="user",
        target_id=user_id,
        reason=reason
    )
    
    db.commit()
    return {"message": f"User {user.username} has been banned"}

@router.put("/users/{user_id}/unban")
async def unban_user(
    user_id: int,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.status = "active"
    user.ban_reason = None
    db.commit()
    return {"message": f"User {user.username} has been unbanned"}

# Content Moderation
@router.put("/artworks/{artwork_id}/feature")
async def feature_artwork(
    artwork_id: int,
    featured: bool,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    artwork = db.query(models.Artwork).filter(models.Artwork.id == artwork_id).first()
    if not artwork:
        raise HTTPException(status_code=404, detail="Artwork not found")
    
    artwork.is_featured = featured
    db.commit()
    return {"message": f"Artwork featured status updated to {featured}"}

@router.put("/artworks/{artwork_id}/moderate")
async def moderate_artwork(
    artwork_id: int,
    action: str,  # "hide", "restore", or "delete"
    reason: str,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    artwork = db.query(models.Artwork).filter(models.Artwork.id == artwork_id).first()
    if not artwork:
        raise HTTPException(status_code=404, detail="Artwork not found")
    
    if action == "hide":
        artwork.status = "hidden"
        artwork.moderation_reason = reason
        message = "Artwork hidden"
    elif action == "restore":
        artwork.status = "active"
        artwork.moderation_reason = None
        message = "Artwork restored"
    elif action == "delete":
        db.delete(artwork)
        message = "Artwork deleted"
    else:
        raise HTTPException(status_code=400, detail="Invalid action")
    
    db.commit()
    return {"message": message}

# Comment Moderation
@router.put("/comments/{comment_id}/moderate")
async def moderate_comment(
    comment_id: int,
    action: str,  # "hide" or "delete"
    reason: str,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    comment = db.query(models.Comment).filter(models.Comment.id == comment_id).first()
    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")
    
    if action == "hide":
        comment.status = "hidden"
        comment.moderation_reason = reason
        db.commit()
        message = "Comment hidden"
    elif action == "delete":
        db.delete(comment)
        db.commit()
        message = "Comment deleted"
    else:
        raise HTTPException(status_code=400, detail="Invalid action")
    
    return {"message": message}

# Analytics
@router.get("/stats")
async def get_stats(
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    total_users = db.query(models.User).count()
    total_artists = db.query(models.User).filter(models.User.role == "artist").count()
    total_artworks = db.query(models.Artwork).count()
    total_likes = db.query(models.Like).count()
    total_comments = db.query(models.Comment).count()
    
    return {
        "total_users": total_users,
        "total_artists": total_artists,
        "total_artworks": total_artworks,
        "total_likes": total_likes,
        "total_comments": total_comments
    }

# Enhanced Analytics
@router.get("/stats/detailed")
async def get_detailed_stats(
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    return {
        "users": {
            "total": db.query(models.User).count(),
            "active": db.query(models.User).filter(models.User.status == "active").count(),
            "banned": db.query(models.User).filter(models.User.status == "banned").count(),
            "artists": db.query(models.User).filter(models.User.role == "artist").count()
        },
        "content": {
            "total_artworks": db.query(models.Artwork).count(),
            "hidden_artworks": db.query(models.Artwork).filter(models.Artwork.status == "hidden").count(),
            "total_comments": db.query(models.Comment).count(),
            "hidden_comments": db.query(models.Comment).filter(models.Comment.status == "hidden").count()
        },
        "engagement": {
            "total_likes": db.query(models.Like).count(),
            "total_discoveries": db.query(models.Discovery).count()
        }
    }

# Moderation Log
@router.get("/moderation-logs", response_model=List[schemas.ModerationLog])
async def get_moderation_logs(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    logs = db.query(models.ModerationLog)\
        .order_by(models.ModerationLog.created_at.desc())\
        .offset(skip)\
        .limit(limit)\
        .all()
    return logs

@router.get("/moderation-logs/search")
async def search_moderation_logs(
    target_type: Optional[str] = None,
    action: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    query = db.query(models.ModerationLog)
    
    if target_type:
        query = query.filter(models.ModerationLog.target_type == target_type)
    if action:
        query = query.filter(models.ModerationLog.action == action)
    if start_date:
        query = query.filter(models.ModerationLog.created_at >= start_date)
    if end_date:
        query = query.filter(models.ModerationLog.created_at <= end_date)
    
    return query.order_by(models.ModerationLog.created_at.desc()).all()

async def log_moderation(
    db: Session,
    admin_id: int,
    action: str,
    target_type: str,
    target_id: int,
    reason: str
):
    log = models.ModerationLog(
        admin_id=admin_id,
        action=action,
        target_type=target_type,
        target_id=target_id,
        reason=reason
    )
    db.add(log)
    db.commit()
    return log 