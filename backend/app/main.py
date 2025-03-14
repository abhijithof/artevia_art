# backend/app/main.py

from fastapi import FastAPI, Depends, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
import asyncio
from . import models
from .database import engine, get_db, Base
from .routers import users, auth, artworks, social, discoveries, categories, admin, profiles
import os
from sqlalchemy import select
from .routers.artworks import PREDEFINED_CATEGORIES

# Initialize FastAPI app
app = FastAPI(title="Artevia API")

# Update CORS middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",  # PHP admin panel
        "http://localhost:3000",  # Frontend
        "*"  # In development only - remove in production
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Create both static and uploads directories
static_dir = os.path.join(os.getcwd(), "static")
uploads_dir = os.path.join(os.getcwd(), "uploads")
os.makedirs(static_dir, exist_ok=True)
os.makedirs(uploads_dir, exist_ok=True)

# Mount both directories
app.mount("/static", StaticFiles(directory=static_dir), name="static")
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")

print(f"Static directory: {static_dir}")
print(f"Uploads directory: {uploads_dir}")

# Include routers
app.include_router(users.router)
app.include_router(auth.router)
app.include_router(artworks.router)
app.include_router(social.router)
app.include_router(discoveries.router)
app.include_router(categories.router)
app.include_router(admin.router)
app.include_router(profiles.router)

# Create async function to create tables
async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

# Create startup event to create tables
@app.on_event("startup")
async def startup_event():
    await create_tables()

# Create async function to create predefined categories
async def create_predefined_categories():
    async with AsyncSession(engine) as db:
        # Check if categories exist
        result = await db.execute(select(models.Category))
        existing = result.scalars().all()
        
        if not existing:
            # Create predefined categories
            for name in PREDEFINED_CATEGORIES:
                category = models.Category(name=name)
                db.add(category)
            await db.commit()

# Create startup event to create predefined categories
@app.on_event("startup")
async def startup_event():
    await create_predefined_categories()

# Basic test route
@app.get("/")
def read_root():
    return {"message": "Welcome to Artevia API"}

# Test database connection
@app.get("/test-db")
async def test_db(db: AsyncSession = Depends(get_db)):
    try:
        # Try to make a simple query
        await db.execute("SELECT 1")
        return {"message": "Database connection successful!"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
