from pydantic import BaseModel
from typing import Optional

class WishlistBase(BaseModel):
    edition_id: str

class WishlistCreate(WishlistBase):
    pass

class WishlistResponse(WishlistBase):
    id: str
    user_id: str

    class Config:
        from_attributes = True
