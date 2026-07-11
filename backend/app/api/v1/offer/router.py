from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.core.database import get_db

router_offer = APIRouter(prefix="/api/v1/offers", tags=["Offers"])

router_offer_announcement = APIRouter(prefix="/api/v1/offered-announcements", tags=["Offered Announcements"])