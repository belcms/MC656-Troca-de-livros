from pydantic import BaseModel, ConfigDict
from typing import Optional

class LocationPydantic(BaseModel):
    cep: str
    
    city: str
    state: str
    country: str
    district: Optional[str] = None
    lat: float
    long: float

    model_config = ConfigDict(from_attributes=True)


class SortPostsByDistanceRequest(BaseModel):
    reference: LocationPydantic
    posts: list[LocationPydantic]
