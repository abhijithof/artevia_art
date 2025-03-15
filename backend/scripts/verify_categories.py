import asyncio
import sys
import os
from sqlalchemy import select
from sqlalchemy.orm import selectinload

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app.database import engine
from app.models import Artwork
from sqlalchemy.ext.asyncio import AsyncSession

async def verify_categories():
    async with AsyncSession(engine) as db:
        try:
            # Get all artworks with their categories using proper loading
            query = (
                select(Artwork)
                .options(selectinload(Artwork.categories))
                .options(selectinload(Artwork.artist))
            )
            
            result = await db.execute(query)
            artworks = result.scalars().all()

            total_artworks = len(artworks)
            artworks_with_categories = 0
            artworks_without_categories = 0

            print("\n=== Category Assignment Report ===")
            for artwork in artworks:
                print(f"\nArtwork ID: {artwork.id}")
                print(f"Title: {artwork.title}")
                print(f"Artist: {artwork.artist.username if artwork.artist else 'Unknown'}")
                if artwork.categories:
                    print(f"Categories: {', '.join(c.name for c in artwork.categories)}")
                    artworks_with_categories += 1
                else:
                    print("No categories assigned")
                    artworks_without_categories += 1

            print("\n=== Summary ===")
            print(f"Total artworks: {total_artworks}")
            print(f"Artworks with categories: {artworks_with_categories}")
            print(f"Artworks without categories: {artworks_without_categories}")
            if total_artworks > 0:
                print(f"Coverage: {(artworks_with_categories/total_artworks)*100:.1f}%")

        except Exception as e:
            print(f"Error: {str(e)}")

if __name__ == "__main__":
    asyncio.run(verify_categories()) 