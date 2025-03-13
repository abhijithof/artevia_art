from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy import select
from . import models
from .constants import PREDEFINED_CATEGORIES

SQLALCHEMY_DATABASE_URL = "sqlite+aiosqlite:///./sql_app.db"

engine = create_async_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
AsyncSessionLocal = sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)

Base = declarative_base()

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session

# Create tables
async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

async def init_categories(db: AsyncSession):
    # Get existing categories
    result = await db.execute(select(models.Category.name))
    existing_categories = {row[0] for row in result.all()}
    
    # Add missing categories from PREDEFINED_CATEGORIES
    for cat_name in PREDEFINED_CATEGORIES:
        if cat_name not in existing_categories:
            category = models.Category(name=cat_name)
            db.add(category)
    
    await db.commit()
