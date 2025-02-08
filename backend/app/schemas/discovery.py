from pydantic import BaseModel
from datetime import datetime

class DiscoveryBase(BaseModel):
    artwork_id: int

class DiscoveryCreate(DiscoveryBase):
    pass

class Discovery(DiscoveryBase):
    id: int
    user_id: int
    discovered_at: datetime

    class Config:
        from_attributes = True 