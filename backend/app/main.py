# backend/app/main.py

from fastapi import FastAPI, Depends, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
import asyncio
from . import models
from .database import engine, get_db, Base, init_categories
from .routers import users, auth, artworks, social, discoveries, categories, admin, profiles
import os

# Initialize FastAPI app
app = FastAPI(title="Artevia API")

# Update CORS middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    max_age=3600,  # Add this to cache preflight requests
)

# Create both static and uploads directories
static_dir = os.path.join(os.getcwd(), "static")
uploads_dir = os.path.join(os.getcwd(), "uploads")
os.makedirs(static_dir, exist_ok=True)
os.makedirs(uploads_dir, exist_ok=True)

# Mount both directories
app.mount("/static", StaticFiles(directory=static_dir), name="static")
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

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
    async with AsyncSession(engine) as session:
        await init_categories(session)

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
