from __future__ import annotations

from datetime import datetime
from typing import List, Tuple, cast

from rapidfuzz import fuzz
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.api.v1.announcements.schemas import FeedAnnouncementResponse
from app.domain.announcements.models import Status, TradeAnnouncement
from app.domain.books.models import Edition


def _normalize_text(value: str | None) -> str:
    if not value:
        return ""

    import re
    import unicodedata

    normalized = unicodedata.normalize("NFKD", value)
    normalized = "".join(character for character in normalized if not unicodedata.combining(character))
    normalized = normalized.casefold()
    normalized = re.sub(r"[^0-9a-z]+", " ", normalized)
    return re.sub(r"\s+", " ", normalized).strip()


def _announcement_timestamp(announcement: TradeAnnouncement) -> float:
    created_at = cast(datetime | None, getattr(announcement, "create_date", None))
    if created_at is None:
        return 0.0
    return created_at.timestamp()


def _field_score(query: str, field_value: str | None) -> int:
    normalized_field = _normalize_text(field_value)
    if not normalized_field:
        return 0

    if query in normalized_field:
        return 100

    return int(
        round(
            max(
                fuzz.partial_ratio(query, normalized_field),
                fuzz.token_sort_ratio(query, normalized_field),
                fuzz.ratio(query, normalized_field),
            )
        )
    )


def _score_query(query: str, announcement: TradeAnnouncement) -> int:
    edition = cast(Edition | None, getattr(announcement, "edition", None))
    book = getattr(edition, "book", None)

    title_score = _field_score(query, getattr(book, "title", None))
    author_score = _field_score(query, getattr(book, "author", None))
    publisher_score = _field_score(query, getattr(edition, "publisher", None))

    return max(title_score, author_score, publisher_score)



class AnnouncementSearchService:
    """Service contract for announcement search.

    Search results are returned as feed cards ordered by relevance.
    """

    def search_announcements(
        self,
        db: Session,
        query: str,
        limit: int = 20,
        offset: int = 0,
    ) -> Tuple[List[FeedAnnouncementResponse], int]:
        normalized_query = _normalize_text(query)
        if not normalized_query:
            return [], 0

        stmt = (
            select(TradeAnnouncement)
            .where(TradeAnnouncement.status == Status.Available)
            .options(
                joinedload(TradeAnnouncement.edition).joinedload(Edition.book),
                joinedload(TradeAnnouncement.user),
            )
            .order_by(TradeAnnouncement.create_date.desc())
        )

        announcements = db.execute(stmt).scalars().unique().all()

        scored_matches: list[tuple[int, TradeAnnouncement]] = []
        for announcement in announcements:
            score = _score_query(normalized_query, announcement)
            if score >= 75:
                scored_matches.append((score, announcement))

        scored_matches.sort(
            key=lambda item: (-item[0], -_announcement_timestamp(item[1]), str(getattr(item[1], "id", "")))
        )

        total = len(scored_matches)
        paginated_matches = scored_matches[offset : offset + limit]

        results: List[FeedAnnouncementResponse] = []
        for _, announcement in paginated_matches:
            edition = cast(Edition | None, getattr(announcement, "edition", None))
            user = getattr(announcement, "user", None)
            book = getattr(edition, "book", None)
            if not edition or not book or not user:
                continue

            publish_year = getattr(edition, "publish_year", 0)
            results.append(
                FeedAnnouncementResponse(
                    id=str(getattr(announcement, "id", "")),
                    title=str(getattr(book, "title", "")),
                    publishYear=int(publish_year),
                    cep=str(getattr(user, "cep", "")),
                    real_photo_url=cast(str | None, getattr(announcement, "real_photo_url", None)),
                )
            )

        return results, total