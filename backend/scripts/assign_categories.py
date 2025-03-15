import asyncio
import sys
import os
from sqlalchemy import text

# Add the parent directory to Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import engine

async def assign_random_categories():
    async with engine.begin() as conn:
        try:
            # This query will randomly assign 1-3 categories to artworks without categories
            query = text("""
                WITH RECURSIVE numbers AS (
                    SELECT 1 as n
                    UNION ALL
                    SELECT n + 1 FROM numbers WHERE n < 3
                ),
                random_assignments AS (
                    SELECT 
                        a.id as artwork_id,
                        c.id as category_id,
                        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY RANDOM()) as rn
                    FROM artworks a
                    CROSS JOIN categories c
                    LEFT JOIN artwork_categories ac ON a.id = ac.artwork_id
                    WHERE ac.artwork_id IS NULL
                )
                INSERT INTO artwork_categories (artwork_id, category_id)
                SELECT artwork_id, category_id
                FROM random_assignments
                WHERE rn <= ABS(RANDOM() % 3) + 1;
            """)
            
            result = await conn.execute(query)
            print(f"Successfully assigned random categories to artworks!")
            
        except Exception as e:
            print(f"Error: {str(e)}")

if __name__ == "__main__":
    asyncio.run(assign_random_categories()) 