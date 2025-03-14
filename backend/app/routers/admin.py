from fastapi import APIRouter, Depends, HTTPException, status, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from .. import models, schemas
from ..database import get_db
from ..auth import get_current_user
from datetime import datetime, timedelta
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, text
from ..auth.auth import verify_password, create_access_token
from sqlalchemy.orm import joinedload

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
@router.get("/users")
async def get_admin_users(
    db: AsyncSession = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    try:
        # Get users with artwork count
        result = await db.execute(
            select(
                models.User,
                func.count(models.Artwork.id).label('artwork_count')
            )
            .outerjoin(models.Artwork)
            .group_by(models.User.id)
            .order_by(models.User.created_at.desc())
        )
        users = result.all()
        
        return [
            {
                "id": user.User.id,
                "username": user.User.username,
                "email": user.User.email,
                "role": user.User.role,
                "status": user.User.status,
                "artwork_count": user.artwork_count,
                "created_at": user.User.created_at
            }
            for user in users
        ]
    except Exception as e:
        print(f"Error fetching users: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.put("/users/{user_id}/ban")
async def ban_user(
    user_id: int,
    ban_data: dict,
    db: AsyncSession = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    try:
        user = await db.get(models.User, user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
            
        user.status = "banned"
        user.ban_reason = ban_data.get("reason")
        await db.commit()
        
        # Log the moderation action
        log = models.ModerationLog(
            admin_id=admin.id,
            action="ban_user",
            target_id=user.id,
            reason=ban_data.get("reason")
        )
        db.add(log)
        await db.commit()
        
        return {"message": "User banned successfully"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/users/{user_id}/unban")
async def unban_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    try:
        user = await db.get(models.User, user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
            
        user.status = "active"
        user.ban_reason = None
        await db.commit()
        
        # Log the moderation action
        log = models.ModerationLog(
            admin_id=admin.id,
            action="unban_user",
            target_id=user.id
        )
        db.add(log)
        await db.commit()
        
        return {"message": "User unbanned successfully"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/users/{user_id}")
async def delete_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    try:
        user = await db.get(models.User, user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
            
        await db.delete(user)
        await db.commit()
        
        return {"message": "User deleted successfully"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

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
async def get_admin_stats(
    db: AsyncSession = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    try:
        # Basic stats
        total_users = await db.scalar(select(func.count(models.User.id)))
        total_artworks = await db.scalar(select(func.count(models.Artwork.id)))
        active_artists = await db.scalar(
            select(func.count(models.User.id))
            .where(models.User.role == "artist")
        )
        total_categories = await db.scalar(select(func.count(models.Category.id)))
        
        # Get user activity data (last 7 days)
        seven_days_ago = datetime.now() - timedelta(days=7)
        activity_data = await db.execute(
            select(
                func.date(models.User.created_at).label('date'),
                func.count(models.User.id).label('count')
            )
            .where(models.User.created_at >= seven_days_ago)
            .group_by(func.date(models.User.created_at))
            .order_by(text('date'))
        )
        activity_results = activity_data.all()
        
        # Get category distribution with explicit joins
        category_data = await db.execute(
            select(
                models.Category.name,
                func.count(models.Artwork.id).label('count')
            )
            .select_from(models.Category)
            .join(models.artwork_categories, models.Category.id == models.artwork_categories.c.category_id, isouter=True)
            .join(models.Artwork, models.artwork_categories.c.artwork_id == models.Artwork.id, isouter=True)
            .group_by(models.Category.id, models.Category.name)
            .order_by(models.Category.name)
        )
        category_results = category_data.all()

        print("Debug - Stats:", {
            "total_users": total_users,
            "active_artists": active_artists,
            "total_artworks": total_artworks,
            "total_categories": total_categories
        })
        
        return {
            "total_users": total_users or 0,
            "total_artworks": total_artworks or 0,
            "active_artists": active_artists or 0,
            "total_categories": total_categories or 0,
            "activity_labels": [str(r.date) for r in activity_results],
            "new_users_data": [r.count for r in activity_results],
            "category_labels": [r.name for r in category_results],
            "category_data": [r.count for r in category_results]
        }
    except Exception as e:
        print(f"Error in get_admin_stats: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

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

@router.post("/login")
async def admin_login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
):
    try:
        # Find user by email
        query = select(models.User).where(models.User.email == form_data.username)
        result = await db.execute(query)
        user = result.scalar_one_or_none()
        
        if not user or not verify_password(form_data.password, user.password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )
            
        if user.role != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized as admin"
            )
            
        access_token = create_access_token(
            data={
                "sub": user.email,
                "role": user.role,
                "user_id": user.id
            }
        )
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "role": user.role,
            "user": {
                "id": user.id,
                "email": user.email,
                "username": user.username
            }
        }
        
    except Exception as e:
        print(f"Admin login error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/artworks")
async def get_admin_artworks(
    db: AsyncSession = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    try:
        result = await db.execute(
            select(models.Artwork)
            .options(
                joinedload(models.Artwork.artist),
                joinedload(models.Artwork.categories)
            )
            .order_by(models.Artwork.created_at.desc())
        )
        artworks = result.unique().scalars().all()
        
        return [
            {
                "id": artwork.id,
                "title": artwork.title,
                "description": artwork.description,
                "image_url": artwork.image_url,
                "latitude": artwork.latitude,
                "longitude": artwork.longitude,
                "artist_id": artwork.artist_id,
                "artist_name": artwork.artist.username if artwork.artist else "Unknown",
                "status": artwork.status,
                "is_featured": artwork.is_featured,
                "created_at": artwork.created_at,
                "categories": [{"id": c.id, "name": c.name} for c in artwork.categories]
            }
            for artwork in artworks
        ]
    except Exception as e:
        print(f"Error fetching artworks: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/categories")
async def get_admin_categories(
    db: AsyncSession = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    try:
        result = await db.execute(
            select(
                models.Category,
                func.count(models.artwork_categories.c.artwork_id).label('artwork_count')
            )
            .outerjoin(models.artwork_categories)
            .group_by(models.Category.id)
            .order_by(models.Category.name)
        )
        categories = result.all()
        
        return [
            {
                "id": category.Category.id,
                "name": category.Category.name,
                "description": category.Category.description,
                "artwork_count": category.artwork_count
            }
            for category in categories
        ]
    except Exception as e:
        print(f"Error fetching categories: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/categories")
async def create_admin_category(
    name: str = Form(...),
    description: str = Form(...),
    db: AsyncSession = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    try:
        new_category = models.Category(
            name=name,
            description=description
        )
        db.add(new_category)
        await db.commit()
        await db.refresh(new_category)
        
        return {
            "id": new_category.id,
            "name": new_category.name,
            "description": new_category.description,
            "artwork_count": 0
        }
    except Exception as e:
        await db.rollback()
        print(f"Error creating category: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/categories/{category_id}")
async def get_category(
    category_id: int,
    db: AsyncSession = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    try:
        category = await db.get(models.Category, category_id)
        if not category:
            raise HTTPException(status_code=404, detail="Category not found")
        return category
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/artworks/{artwork_id}")
async def admin_delete_artwork(
    artwork_id: int,
    db: AsyncSession = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    try:
        artwork = await db.get(models.Artwork, artwork_id)
        if not artwork:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Artwork not found"
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

@router.put("/categories/{category_id}")
async def update_category(
    category_id: int,
    category_data: schemas.CategoryCreate,
    db: AsyncSession = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    try:
        category = await db.get(models.Category, category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found"
            )
        
        category.name = category_data.name
        category.description = category_data.description
        await db.commit()
        await db.refresh(category)
        return category
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.delete("/categories/{category_id}")
async def delete_category(
    category_id: int,
    db: AsyncSession = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    try:
        category = await db.get(models.Category, category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found"
            )
        
        await db.delete(category)
        await db.commit()
        return {"message": "Category deleted successfully"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        ) 