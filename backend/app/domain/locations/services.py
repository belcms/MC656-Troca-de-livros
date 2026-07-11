import httpx
from fastapi import HTTPException
from sqlalchemy.orm import Session
import app.domain.locations.models as location_model
from app.domain.locations.schemas import LocationPydantic

def _calculate_distance(location_a: LocationPydantic, location_b: LocationPydantic) -> float:
        """Calculate the distance between two locations using the Haversine formula"""
        from math import radians, sin, cos, sqrt, atan2

        R = 6371.0  # Radius of the Earth in kilometers

        lat1 = radians(location_a.lat)
        lon1 = radians(location_a.long)
        lat2 = radians(location_b.lat)
        lon2 = radians(location_b.long)

        dlon = lon2 - lon1
        dlat = lat2 - lat1

        a = sin(dlat / 2)**2 + cos(lat1) * cos(lat2) * sin(dlon / 2)**2
        c = 2 * atan2(sqrt(a), sqrt(1 - a))

        distance = R * c
        return distance


async def get_location_by_cep(cep: str, db: Session) -> location_model.location:
    """Fetch location data from an external API or Local DB.
    Args:
        cep: The postal code (CEP) to look up. (ONLY_NUMERIC)
        db: SQLAlchemy session.
    """
    # STREAMING_CHUNK:Checking if location already exists in the database
    existing_location = db.query(location_model.location).filter(location_model.location.cep == cep).first()
    if existing_location:
        return existing_location

    # STREAMING_CHUNK:Fetching location from external API if not found locally
    url = f"https://cep.awesomeapi.com.br/json/{cep}"
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="Error fetching location data")
            
        data = response.json()
        
        # STREAMING_CHUNK:Formatting API response and saving to database
        # Criamos a nova entidade para persistir
        new_location = location_model.location(
            city=data.get("city"),
            state=data.get("state"),
            country='Brasil',
            district=data.get("district"),
            lat=data.get("lat"),
            long=data.get("lng"),
            cep=data.get("cep").replace("-", ""), # Removendo traços caso a API devolva formatado
        )
        
        # Inserimos a nova localização no banco para as próximas consultas serem instantâneas
        db.add(new_location)
        db.commit()
        db.refresh(new_location)
        
        return new_location


async def sort_posts_by_distance_from_A(location_a: location_model.LocationPydantic, posts: list[dict]) -> list[dict]:
    """Sort posts by distance from a given location.

    Args:
        location_a: The reference location to calculate distances from.
        posts: A list of posts, each containing a 'location' key with a LocationPydantic object.
    """


    sorted_posts = sorted(posts, key=lambda post: _calculate_distance(location_a, post['location']))
    return sorted_posts