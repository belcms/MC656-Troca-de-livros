from sqlalchemy.orm import Session


def test_update_book_data_persists_correctly(db_session: Session, seed_announcement):
    """
    Test that verifies updated book, edition and announcement fields
    are correctly persisted in the database.
    """

    # Create initial test data
    data = seed_announcement()
    announcement = data["announcement"]
    edition = data["edition"]
    book = data["book"]

    # Simulate the same updates performed by the edit flow
    book.title = "Novo Titulo"
    book.author = "Novo Autor"
    book.synopsis = "Nova sinopse de teste"
    book.genre = type(book.genre).Fantasy

    edition.publisher = "Nova Editora"
    edition.language = type(edition.language).PT_br
    edition.publish_year = 2001
    edition.number_of_pages = 321

    announcement.description = "Nova descricao de teste"
    announcement.status = type(announcement.status).Reserved
    announcement.condition = type(announcement.condition).Used
    announcement.real_photo_url = "https://example.com/new-cover.jpg"

    db_session.commit()

    # Reload from database
    db_session.refresh(book)
    db_session.refresh(edition)
    db_session.refresh(announcement)

    # Assert persisted values
    assert book.title == "Novo Titulo"
    assert book.author == "Novo Autor"
    assert book.synopsis == "Nova sinopse de teste"
    assert book.genre.value == "Fantasy"

    assert edition.publisher == "Nova Editora"
    assert edition.language.value == "PT-br"
    assert edition.publish_year == 2001
    assert edition.number_of_pages == 321

    assert announcement.description == "Nova descricao de teste"
    assert announcement.status.value == "Reserved"
    assert announcement.condition.value == "Used"
    assert announcement.real_photo_url == "https://example.com/new-cover.jpg"