from __future__ import annotations

from sqlalchemy.orm import Session


class AnnouncementSearchService:
    """Service contract for announcement search.

    The implementation will be added in a later step.
    """

    def search_announcements(
        self,
        db: Session,
        query: str,
        limit: int = 20,
        offset: int = 0,
    ):
        raise NotImplementedError("Announcement search is not implemented yet")