from ..models import ActivityLog
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime
from fastapi import Request

async def log_activity(
    db: AsyncSession,
    user_email: str,
    action: str,
    details: str,
    level: str = "INFO",
    request: Request = None
):
    ip_address = request.client.host if request else "Unknown"
    
    log = ActivityLog(
        user_email=user_email,
        action=action,
        details=details,
        ip_address=ip_address,
        level=level
    )
    
    db.add(log)
    await db.commit() 