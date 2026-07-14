from fastapi import APIRouter, HTTPException, Depends
from typing import List
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.domain.locations.schemas import LocationPydantic, SortPostsByDistanceRequest
from app.domain.locations import services

router = APIRouter(
    prefix="/api/v1/locations",
    tags=["Locations"],
)

@router.get("/{cep}", response_model= LocationPydantic, summary="Get Location by CEP", description="Retrieves Location data based on the provided postal code (CEP).")
async def get_location_by_cep(cep: str, db: Session = Depends(get_db)):
    """
    Get location data by postal code (CEP).

    Args:
        cep (str): The postal code (CEP) to look up. Must be numeric.
    """
    
    # Passamos a sessão do banco de dados (db) recém injetada para o service
    location = await services.get_location_by_cep(cep, db)
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")
    return location

#get sorted posts by distance from a given location
@router.post("/sort_posts_by_distance", response_model=List[LocationPydantic], summary="Sort Posts by Distance", description="Sorts a list of posts based on their distance from a specified location.")
async def sort_posts_by_distance_from_A(body: SortPostsByDistanceRequest):
    """
    Sort posts by distance from a given location.

    Args:
        location_a (LocationPydantic): The reference location to calculate distances from.
        posts (List[dict]): A list of posts, each containing a 'location' key with a LocationPydantic object.
    """
    
    sorted_posts = await services.sort_posts_by_distance_from_A(body.reference, body.posts)
    return sorted_posts
