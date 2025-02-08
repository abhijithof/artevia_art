from pydantic import BaseModel
from datetime import datetime

class CommentBase(BaseModel):
    text: str

class CommentCreate(CommentBase):
    pass

class Comment(CommentBase):
    id: int
    user_id: int
    artwork_id: int
    created_at: datetime

    class Config:
        from_attributes = True

class Like(BaseModel):
    id: int
    user_id: int
    artwork_id: int
    created_at: datetime

    class Config:
        from_attributes = True 