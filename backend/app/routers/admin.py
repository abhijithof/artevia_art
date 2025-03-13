from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload, selectinload
from typing import List, Optional
from .. import models, schemas
from ..database import get_db
from ..auth import get_current_user, get_current_active_user
from datetime import datetime, timedelta
import csv
from io import StringIO
from fastapi.responses import StreamingResponse
from sqlalchemy import or_, func, text, select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, and_
from ..models import artwork_categories

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
    db: AsyncSession = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    result = await db.execute(
        select(models.User)
        .offset(skip)
        .limit(limit)
    )
    users = result.scalars().all()
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
    ban_data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    result = await db.execute(
        select(models.User).filter(models.User.id == user_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.role == "admin":
        raise HTTPException(status_code=400, detail="Cannot ban admin users")
    
    user.status = "banned"
    user.ban_reason = ban_data.get("reason")
    await db.commit()
    return {"message": f"User {user.username} has been banned"}

@router.put("/users/{user_id}/unban")
async def unban_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    result = await db.execute(
        select(models.User).filter(models.User.id == user_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.status = "active"
    user.ban_reason = None
    await db.commit()
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
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # Get total users (including all statuses)
    result = await db.execute(
        select(func.count(models.User.id))
        .select_from(models.User)
    )
    total_users = result.scalar()
    
    # Get active artists
    result = await db.execute(
        select(func.count(models.User.id))
        .select_from(models.User)
        .where(
            and_(
                models.User.role == "artist",
                models.User.status == "active"
            )
        )
    )
    active_artists = result.scalar()
    
    # Get total artworks
    result = await db.execute(
        select(func.count(models.Artwork.id))
        .select_from(models.Artwork)
    )
    total_artworks = result.scalar()
    
    # Get predefined categories from PREDEFINED_CATEGORIES
    predefined_categories = [
        "Digital Art",
        "Traditional",
        "Photography",
        "Sculpture",
        "Mixed Media"
    ]
    
    # Insert categories if they don't exist
    for category_name in predefined_categories:
        result = await db.execute(
            select(models.Category).where(models.Category.name == category_name)
        )
        if not result.scalar():
            new_category = models.Category(name=category_name)
            db.add(new_category)
    
    await db.commit()
    
    # Get categories and their artwork counts
    result = await db.execute(
        select(models.Category.name, func.count(artwork_categories.c.artwork_id))
        .outerjoin(artwork_categories)
        .group_by(models.Category.name)
    )
    categories = result.all()
    
    # Get total categories
    result = await db.execute(select(func.count(models.Category.id)))
    total_categories = result.scalar()
    
    # Format category data for charts
    category_labels = [cat[0] for cat in categories]
    category_data = [cat[1] for cat in categories]

    return {
        "total_users": total_users,
        "active_artists": active_artists,
        "total_artworks": total_artworks,
        "total_categories": total_categories,
        "category_labels": category_labels,
        "category_data": category_data,
        "activity_labels": [
            (datetime.now() - timedelta(days=i)).strftime('%Y-%m-%d')
            for i in range(6, -1, -1)
        ],
        "new_users_data": await get_new_users_data(db)
    }

async def get_new_users_data(db: AsyncSession):
    data = []
    for i in range(6, -1, -1):
        date = datetime.now() - timedelta(days=i)
        result = await db.execute(
            select(func.count(models.User.id))
            .where(func.date(models.User.created_at) == date.date())
        )
        data.append(result.scalar() or 0)
    return data

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

@router.get("/users/export")
async def export_users(
    search: Optional[str] = None,
    sort_by: Optional[str] = None,
    sort_order: Optional[str] = None,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    # Build the base query
    query = db.query(models.User)
    
    # Apply search filter
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            or_(
                models.User.username.ilike(search_term),
                models.User.email.ilike(search_term)
            )
        )
    
    # Apply sorting
    if sort_by:
        order_column = getattr(models.User, sort_by)
        if sort_order == "desc":
            order_column = order_column.desc()
        query = query.order_by(order_column)
    else:
        query = query.order_by(models.User.created_at.desc())
    
    users = query.all()
    
    # Create CSV in memory
    output = StringIO()
    writer = csv.writer(output)
    
    # Write headers
    writer.writerow([
        'ID',
        'Username',
        'Email',
        'Status',
        'Role',
        'Joined Date',
        'Last Login',
        'Artworks Count',
        'Created At',
        'Updated At'
    ])
    
    # Write user data
    for user in users:
        artworks_count = db.query(models.Artwork).filter(models.Artwork.artist_id == user.id).count()
        writer.writerow([
            user.id,
            user.username,
            user.email,
            user.status,
            user.role,
            user.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            user.last_login.strftime('%Y-%m-%d %H:%M:%S') if user.last_login else '',
            artworks_count,
            user.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            user.updated_at.strftime('%Y-%m-%d %H:%M:%S') if user.updated_at else ''
        ])
    
    # Prepare the response
    output.seek(0)
    
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={
            'Content-Disposition': f'attachment; filename="users_export_{datetime.now().strftime("%Y%m%d_%H%M%S")}.csv"'
        }
    )

@router.get("/users/stats")
async def get_user_stats(
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    """Get detailed user statistics for admin dashboard"""
    total_users = db.query(models.User).count()
    active_users = db.query(models.User).filter(models.User.status == "active").count()
    banned_users = db.query(models.User).filter(models.User.status == "banned").count()
    artists = db.query(models.User).filter(models.User.role == "artist").count()
    
    # Get new users in last 30 days
    thirty_days_ago = datetime.now() - timedelta(days=30)
    new_users = db.query(models.User)\
        .filter(models.User.created_at >= thirty_days_ago)\
        .count()
    
    # Get user engagement stats
    total_artworks = db.query(models.Artwork).count()
    total_likes = db.query(models.Like).count()
    total_comments = db.query(models.Comment).count()
    
    # Get most active users
    most_active = db.query(
        models.User,
        func.count(models.Artwork.id).label('artwork_count')
    )\
        .join(models.Artwork, models.User.id == models.Artwork.artist_id)\
        .group_by(models.User.id)\
        .order_by(text('artwork_count DESC'))\
        .limit(5)\
        .all()
    
    # Get daily activity for the last 30 days
    daily_activity = []
    
    for day in range(30):
        date = thirty_days_ago + timedelta(days=day)
        next_date = date + timedelta(days=1)
        
        new_users_count = db.query(models.User)\
            .filter(
                models.User.created_at >= date,
                models.User.created_at < next_date
            ).count()
            
        active_users_count = db.query(models.User)\
            .filter(
                models.User.last_login >= date,
                models.User.last_login < next_date
            ).count()
            
        daily_activity.append({
            "date": date.strftime('%Y-%m-%d'),
            "newUsers": new_users_count,
            "activeUsers": active_users_count
        })

    return {
        "overview": {
            "total_users": total_users,
            "active_users": active_users,
            "banned_users": banned_users,
            "artists": artists,
            "new_users_30d": new_users
        },
        "engagement": {
            "total_artworks": total_artworks,
            "total_likes": total_likes,
            "total_comments": total_comments,
            "avg_artworks_per_artist": round(total_artworks / artists if artists > 0 else 0, 2)
        },
        "most_active_users": [{
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "artwork_count": count
        } for user, count in most_active],
        "activity": daily_activity
    }

@router.get("/users/filter")
async def filter_users(
    status: Optional[str] = None,
    role: Optional[str] = None,
    joined_after: Optional[datetime] = None,
    joined_before: Optional[datetime] = None,
    min_artworks: Optional[int] = None,
    max_artworks: Optional[int] = None,
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    """Advanced user filtering for admin"""
    query = db.query(models.User)
    
    if status:
        query = query.filter(models.User.status == status)
    if role:
        query = query.filter(models.User.role == role)
    if joined_after:
        query = query.filter(models.User.created_at >= joined_after)
    if joined_before:
        query = query.filter(models.User.created_at <= joined_before)
        
    # Handle artwork count filtering
    if min_artworks is not None or max_artworks is not None:
        artwork_count = db.query(
            models.Artwork.artist_id,
            func.count(models.Artwork.id).label('count')
        )\
            .group_by(models.Artwork.artist_id)\
            .subquery()
            
        query = query.outerjoin(artwork_count, models.User.id == artwork_count.c.artist_id)
        
        if min_artworks is not None:
            query = query.filter(artwork_count.c.count >= min_artworks)
        if max_artworks is not None:
            query = query.filter(artwork_count.c.count <= max_artworks)
    
    total = query.count()
    users = query.offset(skip).limit(limit).all()
    
    # Get artwork counts for returned users
    user_ids = [user.id for user in users]
    artwork_counts = dict(
        db.query(
            models.Artwork.artist_id,
            func.count(models.Artwork.id)
        )
        .filter(models.Artwork.artist_id.in_(user_ids))
        .group_by(models.Artwork.artist_id)
        .all()
    )
    
    return {
        "total": total,
        "users": [{
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "status": user.status,
            "role": user.role,
            "joined_date": user.created_at,
            "artwork_count": artwork_counts.get(user.id, 0)
        } for user in users]
    }

@router.get("/users")
async def list_users(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # Using proper async syntax
    result = await db.execute(
        select(models.User)
        .offset(skip)
        .limit(limit)
    )
    users = result.scalars().all()
    return users

@router.get("/artworks")
async def list_artworks(
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    stmt = (
        select(models.Artwork)
        .join(models.User, models.Artwork.artist_id == models.User.id)
        .options(
            selectinload(models.Artwork.categories),
            selectinload(models.Artwork.artist)
        )
    )
    
    result = await db.execute(stmt)
    artworks = result.scalars().all()
    
    base_url = "http://localhost:8000"
    
    return [
        {
            "id": artwork.id,
            "title": artwork.title,
            "description": artwork.description,
            "image_url": f"{base_url}/uploads/{artwork.image_url.split('/')[-1]}" if artwork.image_url else None,
            "latitude": artwork.latitude,
            "longitude": artwork.longitude,
            "artist_id": artwork.artist_id,
            "artist_name": artwork.artist.username if artwork.artist else "Unknown",
            "status": artwork.status,
            "is_featured": artwork.is_featured,
            "created_at": artwork.created_at,
            "categories": [{
                "id": cat.id,
                "name": cat.name
            } for cat in artwork.categories] if artwork.categories else []
        }
        for artwork in artworks
    ]

@router.get("/categories")
async def list_categories(
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # Get categories with artwork counts
    stmt = (
        select(
            models.Category,
            func.count(models.artwork_categories.c.artwork_id).label('artwork_count')
        )
        .outerjoin(
            models.artwork_categories,
            models.Category.id == models.artwork_categories.c.category_id
        )
        .group_by(
            models.Category.id,
            models.Category.name,
            models.Category.description
        )
    )
    
    result = await db.execute(stmt)
    categories = result.all()
    
    return [
        {
            "id": category.id,
            "name": category.name,
            "description": category.description,
            "artwork_count": int(artwork_count) if artwork_count else 0
        }
        for category, artwork_count in categories
    ]

@router.get("/activity-logs")
async def get_activity_logs(
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    stmt = (
        select(models.ActivityLog)
        .order_by(models.ActivityLog.timestamp.desc())
    )
    
    result = await db.execute(stmt)
    logs = result.scalars().all()
    
    return [
        {
            "timestamp": log.timestamp.strftime("%Y-%m-%d %H:%M:%S"),
            "user_email": log.user_email,
            "action": log.action,
            "details": log.details,
            "ip_address": log.ip_address,
            "level": log.level
        }
        for log in logs
    ]

@router.delete("/users/{user_id}")
async def delete_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    result = await db.execute(
        select(models.User).filter(models.User.id == user_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    await db.delete(user)
    await db.commit()
    return {"message": "User deleted"} 