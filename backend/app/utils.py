from passlib.context import CryptContext
import bcrypt
import os
from fastapi import UploadFile, Query
from datetime import datetime
from math import sin, cos, sqrt, atan2, radians
from typing import Optional, List
from sqlalchemy import or_

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Create upload directory if it doesn't exist
UPLOAD_DIR = "static/images"
os.makedirs(UPLOAD_DIR, exist_ok=True)

def get_password_hash(password: str):
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str):
    return pwd_context.verify(plain_password, hashed_password)

async def save_image(file: UploadFile) -> str:
    """Save image and return file path"""
    # Create unique filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    file_extension = os.path.splitext(file.filename)[1]
    filename = f"{timestamp}{file_extension}"
    
    # Save file
    file_path = os.path.join(UPLOAD_DIR, filename)
    with open(file_path, "wb") as buffer:
        content = await file.read()
        buffer.write(content)
    
    # Return relative path
    return f"/images/{filename}"

def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two points in kilometers using the Haversine formula"""
    R = 6371  # Earth's radius in kilometers
    
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * atan2(sqrt(a), sqrt(1-a))
    distance = R * c
    
    return distance

class PaginationParams:
    def __init__(
        self,
        skip: int = Query(default=0, ge=0),
        limit: int = Query(default=10, ge=1, le=100),
        sort_by: Optional[str] = Query(default=None),
        order: Optional[str] = Query(default="desc", regex="^(asc|desc)$")
    ):
        self.skip = skip
        self.limit = limit
        self.sort_by = sort_by
        self.order = order

def search_filter(query, model, search_term: str, fields: List[str]):
    """Generic search across specified fields"""
    if not search_term:
        return query
    
    conditions = []
    for field in fields:
        conditions.append(getattr(model, field).ilike(f"%{search_term}%"))
    return query.filter(or_(*conditions))

async def save_uploaded_file(file: UploadFile) -> str:
    """Save an uploaded file and return its relative path."""
    UPLOAD_DIR = "static/uploads"
    
    # Create uploads directory if it doesn't exist
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    
    # Generate unique filename using timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{timestamp}_{file.filename}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    
    # Save the file
    content = await file.read()
    with open(file_path, "wb") as f:
        f.write(content)
    
    # Return the relative path
    return f"/uploads/{filename}" 