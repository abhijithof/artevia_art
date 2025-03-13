from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class ModerationLogBase(BaseModel):
    action: str
    target_type: str  # e.g., "artwork", "user", "comment"
    target_id: int
    reason: Optional[str] = None

class ModerationLogCreate(ModerationLogBase):
    pass

class ModerationLog(ModerationLogBase):
    id: int
    moderator_id: int
    created_at: datetime

    class Config:
        from_attributes = True

class ArtworkModeration(BaseModel):
    action: str  # "delete", "hide", or "restore"
    reason: str 