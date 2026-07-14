from __future__ import annotations

from typing import Any

from app.domain.announcements.search import AnnouncementSearchService


def _dump_result(item: Any) -> dict[str, Any]:
    if hasattr(item, "model_dump"):
        return item.model_dump(by_alias=True)
    return item


def _run_search(db_session, query: str):
    service = AnnouncementSearchService()
    return service.search_announcements(db_session, query)


def test_search_returns_exact_title_match_and_total(db_session, search_catalog):
    results, total = _run_search(db_session, "Senhor dos Anéis")

    assert total == 1
    assert len(results) == 1
    dumped = _dump_result(results[0])
    assert dumped["title"] == "Senhor dos Anéis"
    assert dumped["id"] == search_catalog["by_title"]["Senhor dos Anéis"]["announcement"].id


def test_search_returns_partial_title_match(db_session, search_catalog):
    results, total = _run_search(db_session, "Senhor dos")

    assert total == 1
    assert len(results) == 1
    assert _dump_result(results[0])["title"] == "Senhor dos Anéis"


def test_search_by_author_exact_and_partial_returns_all_matches(db_session, search_catalog):
    for query in ("J. R. R. Tolkien", "Tolkien"):
        results, total = _run_search(db_session, query)

        assert total == 2
        assert len(results) == 2
        returned_titles = {_dump_result(item)["title"] for item in results}
        assert returned_titles == {"Senhor dos Anéis", "O Hobbit"}


def test_search_by_publisher_returns_matching_announcements(db_session, search_catalog):
    publisher_results, publisher_total = _run_search(db_session, "Addison-Wesley")

    assert publisher_total == 2
    assert {_dump_result(item)["title"] for item in publisher_results} == {
        "Refactoring",
        "The Pragmatic Programmer",
    }


def test_search_numeric_title_like_1984_matches(db_session, search_catalog):
    results, total = _run_search(db_session, "1984")

    assert total == 1
    assert len(results) == 1
    assert _dump_result(results[0])["title"] == "1984"



def test_search_finds_missing_letters_typos_and_inverted_characters(db_session, search_catalog):
    cases = [
        ("Hary", {"Harry Potter e a Pedra Filosofal", "Harry Potter e a Câmara Secreta"}, 2),
        ("Harrt Potter", {"Harry Potter e a Pedra Filosofal", "Harry Potter e a Câmara Secreta"}, 2),
        ("Algrenon", {"Flores para Algernon"}, 1),
    ]

    for query, expected_titles, minimum_total in cases:
        results, total = _run_search(db_session, query)

        returned_titles = {_dump_result(item)["title"] for item in results}
        assert total >= minimum_total
        assert len(results) >= minimum_total
        assert expected_titles.issubset(returned_titles)


def test_search_is_case_and_accent_insensitive(db_session, search_catalog):
    lower_results, lower_total = _run_search(db_session, "flores para algernon")
    upper_results, upper_total = _run_search(db_session, "FLORES PARA ALGERNON")
    accent_results, accent_total = _run_search(db_session, "capitaes da areia")

    assert lower_total == 1
    assert upper_total == 1
    assert accent_total == 1
    assert _dump_result(lower_results[0])["title"] == "Flores para Algernon"
    assert _dump_result(upper_results[0])["title"] == "Flores para Algernon"
    assert _dump_result(accent_results[0])["title"] == "Capitães da Areia"


def test_search_returns_empty_list_and_zero_total_when_no_match(db_session):
    results, total = _run_search(db_session, "nao existe esse anuncio")

    assert results == []
    assert total == 0