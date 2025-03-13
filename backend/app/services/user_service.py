from typing import List, Optional
from sqlalchemy import select, func
from ..models.user import User
from ..database import get_db

class UserService:
    def __init__(self, db=Depends(get_db)):
        self.db = db

    async def get_users_for_export(
        self,
        search: Optional[str] = None,
        sort_by: Optional[str] = None,
        sort_order: Optional[str] = None
    ) -> List[User]:
        query = select(User)

        # Apply search filter if provided
        if search:
            search_term = f"%{search}%"
            query = query.where(
                or_(
                    User.username.ilike(search_term),
                    User.email.ilike(search_term)
                )
            )

        # Apply sorting
        if sort_by:
            order_column = getattr(User, sort_by)
            if sort_order == "desc":
                order_column = order_column.desc()
            query = query.order_by(order_column)
        else:
            # Default sorting by joined_date desc
            query = query.order_by(User.joined_date.desc())

        # Execute query and return all results
        result = await self.db.execute(query)
        users = result.scalars().all()

        # Fetch artworks count for each user
        for user in users:
            artworks_count = await self.db.execute(
                select(func.count()).where(Artwork.artist_id == user.id)
            )
            user.artworks_count = artworks_count.scalar()

        return users 