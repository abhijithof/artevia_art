# backend/app/main.py

from fastapi import FastAPI, Depends, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
import asyncio
from . import models
from .database import engine, get_db, Base, init_db
from .routers import users, auth, artworks, social, discoveries, categories, admin, profiles

# Initialize FastAPI app
app = FastAPI(title="Artevia API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:63907", "http://localhost:3000"],  # Add your Flutter web port
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files directory
app.mount("/images", StaticFiles(directory="static/images"), name="images")

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
    await init_db()

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
