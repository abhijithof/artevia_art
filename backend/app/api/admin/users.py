from fastapi import APIRouter, Depends, Query
from typing import Optional
from ...dependencies import get_current_admin
from ...services.user_service import UserService
from fastapi.responses import StreamingResponse
import csv
from io import StringIO
from datetime import datetime

router = APIRouter()

@router.get("/export")
async def export_users(
    search: Optional[str] = Query(None),
    sort_by: Optional[str] = Query(None),
    sort_order: Optional[str] = Query(None),
    current_admin = Depends(get_current_admin),
    user_service: UserService = Depends()
):
    # Get all users without pagination
    users = await user_service.get_users_for_export(
        search=search,
        sort_by=sort_by,
        sort_order=sort_order
    )
    
    # Create StringIO object to write CSV data
    output = StringIO()
    writer = csv.writer(output)
    
    # Write headers
    writer.writerow([
        'ID',
        'Username',
        'Email',
        'Status',
        'Joined Date',
        'Artworks Count',
        'Last Login',
        'Created At',
        'Updated At'
    ])
    
    # Write user data
    for user in users:
        writer.writerow([
            user.id,
            user.username,
            user.email,
            user.status,
            user.joined_date.strftime('%Y-%m-%d %H:%M:%S'),
            user.artworks_count,
            user.last_login.strftime('%Y-%m-%d %H:%M:%S') if user.last_login else '',
            user.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            user.updated_at.strftime('%Y-%m-%d %H:%M:%S')
        ])
    
    # Prepare the response
    output.seek(0)
    
    # Generate filename with current timestamp
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f"users_export_{timestamp}.csv"
    
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={
            'Content-Disposition': f'attachment; filename="{filename}"'
        }
    ) 