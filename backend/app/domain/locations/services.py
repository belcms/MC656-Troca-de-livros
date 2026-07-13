import re
from math import atan2, cos, radians, sin, sqrt

import httpx
from fastapi import HTTPException
from sqlalchemy.orm import Session

import app.domain.locations.models as location_model
from app.domain.locations.schemas import LocationPydantic


def normalize_cep(cep: str | None) -> str | None:
    if cep is None:
        return None

    clean_cep = re.sub(r"\D", "", str(cep))
    if not clean_cep:
        return None

    if len(clean_cep) != 8:
        raise HTTPException(status_code=400, detail="CEP must contain exactly 8 digits")

    return clean_cep


def _location_from_api_data(data: dict, fallback_cep: str) -> location_model.location:
    cep = normalize_cep(data.get("cep") or fallback_cep)
    city = data.get("city")
    state = data.get("state")
    lat = data.get("lat")
    long = data.get("lng")

    if not cep or not city or not state or lat is None or long is None:
        raise HTTPException(status_code=404, detail="Location not found for CEP")

    try:
        lat_value = float(lat)
        long_value = float(long)
    except (TypeError, ValueError):
        raise HTTPException(status_code=404, detail="Location not found for CEP")

    return location_model.location(
        cep=cep,
        city=city,
        state=state,
        country=data.get("country") or "Brasil",
        district=data.get("district"),
        lat=lat_value,
        long=long_value,
    )


def get_or_create_location_by_cep(cep: str | None, db: Session) -> location_model.location:
    clean_cep = normalize_cep(cep)
    if clean_cep is None:
        raise HTTPException(status_code=400, detail="CEP is required")

    existing_location = (
        db.query(location_model.location)
        .filter(location_model.location.cep == clean_cep)
        .first()
    )
    if existing_location:
        return existing_location

    url = f"https://cep.awesomeapi.com.br/json/{clean_cep}"
    with httpx.Client(timeout=5.0) as client:
        response = client.get(url)

    if response.status_code != 200:
        raise HTTPException(status_code=404, detail="Location not found for CEP")

    new_location = _location_from_api_data(response.json(), clean_cep)
    db.add(new_location)
    db.commit()
    db.refresh(new_location)

    return new_location


def _calculate_distance(location_a: LocationPydantic, location_b: LocationPydantic) -> float:
    """Calculate the distance between two locations using the Haversine formula."""
    radius_km = 6371.0

    lat1 = radians(location_a.lat)
    lon1 = radians(location_a.long)
    lat2 = radians(location_b.lat)
    lon2 = radians(location_b.long)

    dlon = lon2 - lon1
    dlat = lat2 - lat1

    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))

    return radius_km * c


async def get_location_by_cep(cep: str, db: Session) -> location_model.location:
    """Fetch location data from the local DB or from the external CEP API."""
    return get_or_create_location_by_cep(cep, db)


async def sort_posts_by_distance_from_A(location_a: LocationPydantic, posts: list) -> list:
    """Sort locations/posts by distance, leaving invalid or missing locations last."""
    def sort_key(post):
        location = post.get("location") if isinstance(post, dict) else post
        if location is None:
            return float("inf")

        try:
            return _calculate_distance(location_a, location)
        except (AttributeError, TypeError, ValueError):
            return float("inf")

    return sorted(posts, key=sort_key)
