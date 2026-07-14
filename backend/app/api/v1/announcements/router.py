from fastapi import APIRouter, Depends, Query, UploadFile, File, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db

from app.api.v1.announcements.schemas import FeedAnnouncementResponse, SearchAnnouncementsResponse
import app.domain.announcements.schemas as announcements_schemas
from app.domain.announcements.schemas import PhotoResponse
from app.services.photo_service import add_photo_to_announcement
from app.domain.announcements.services import (
    get_announcement_details,
    get_feed_announcements,
    create_announcement as service_create_announcement,
)
from app.domain.announcements.search import AnnouncementSearchService
from app.api.v1.announcements.schemas import DeletePhotoRequest
from app.services.storage_service import delete_image_from_supabase
from app.services.photo_service import remove_photo_from_announcement

router = APIRouter(prefix="/api/v1/announcements", tags=["announcements"])

@router.get("/search", response_model=SearchAnnouncementsResponse, summary="Search announcements")
def search_announcements_route(
    query: str = Query(..., min_length=1, description="Search term used to match announcements"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """Search announcements by book title, author, publisher, or year.

    Returns a lightweight envelope with the matched cards and the total
    number of hits, which the frontend can use for pagination and counters.
    """

    service = AnnouncementSearchService()
    results, total = service.search_announcements(db=db, query=query, limit=limit, offset=offset)
    return {"results": results, "total": total}

@router.get("/details/{id}")
def get_book_details_route(id: str, db: Session = Depends(get_db)):
    """Retrieve details of a specific announcement by its ID.

        The endpoint delegates to the announcements service to fetch the full 
        details of a single announcement.

        Args:
            id: Announcement identifier from path parameters.
            db: SQLAlchemy session injected by FastAPI.

        Returns:
            The detailed announcement payload.
    """
    return get_announcement_details(db, id)

@router.get("/feed", response_model=list[FeedAnnouncementResponse])
def feed_announcements_route(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """Return the feed list used by the main announcements timeline.

    The endpoint delegates to the announcements service to retrieve a paginated
    list of announcements for the general feed.

    Args:
        limit: Maximum number of announcements to return. Constrained between 1 and 100.
        offset: Number of announcements to skip for pagination.
        db: SQLAlchemy session injected by FastAPI.

    Returns:
        list[FeedAnnouncementResponse]: A list of announcements for the feed.
    """
    return get_feed_announcements(db, limit=limit, offset=offset)

@router.post("/{user_id}", status_code=201)
def create_announcement_route(user_id: str, body: announcements_schemas.TradeAnnouncementPydantic, db: Session = Depends(get_db)):
    """Create a new trade announcement for a specific user.

    The endpoint delegates to the announcements service to persist a new
    announcement associated with the given user ID.

    Args:
        user_id: User identifier from path parameters.
        body: The payload containing the trade announcement details.
        db: SQLAlchemy session injected by FastAPI.

    Returns:
        The created announcement payload with HTTP 201 status.
    """
    return service_create_announcement(user_id, body, db)

@router.post("/{announcement_id}/photos", response_model=PhotoResponse, status_code=status.HTTP_201_CREATED)
def upload_announcement_photo_endpoint(
    announcement_id: str, 
    file: UploadFile = File(...), 
    db: Session = Depends(get_db)
):
    """
    Faz o upload de uma foto para um anúncio específico.
    """
    # Você pode colocar uma validação aqui para checar se o file.content_type é 'image/jpeg' ou 'image/png'
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="O arquivo deve ser uma imagem.")

    try:
        saved_photo = add_photo_to_announcement(db=db, announcement_id=announcement_id, file=file)
        return saved_photo
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"Erro ao salvar foto: {str(e)}"
        )
    


@router.delete("/{announcement_id}/photos")
def delete_announcement_photo(
    announcement_id: str, 
    request: DeletePhotoRequest, 
    db: Session = Depends(get_db) # <-- Injeta a sessão do banco
):
    try:
        # 1. Apaga o arquivo físico do Supabase
        delete_image_from_supabase(request.photo_url)
        
        # 2. Apaga o registro da tabela PhotoTradeAnnouncement
        remove_photo_from_announcement(db, announcement_id, request.photo_url)
        
        return {"message": "Foto deletada com sucesso!"}
        
    except Exception as e:
        # Vai estourar erro 500 se qualquer um dos dois falhar
        raise HTTPException(status_code=500, detail=f"Erro ao deletar foto: {str(e)}")
    

