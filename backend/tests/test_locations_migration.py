import importlib.util
from pathlib import Path

from alembic.migration import MigrationContext
from alembic.operations import Operations
from sqlalchemy import create_engine, inspect, text


MIGRATION_PATH = (
    Path(__file__).parents[1]
    / "alembic"
    / "versions"
    / "20260715_01_locations.py"
)


def _load_migration():
    spec = importlib.util.spec_from_file_location("locations_migration", MIGRATION_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_locations_migration_preserves_legacy_user_cep(monkeypatch):
    engine = create_engine("sqlite:///:memory:")
    migration = _load_migration()

    with engine.begin() as connection:
        connection.execute(
            text(
                "CREATE TABLE users ("
                "id VARCHAR(36) PRIMARY KEY, "
                "cep VARCHAR(20)"
                ")"
            )
        )
        connection.execute(
            text(
                "CREATE TABLE trade_announcements ("
                "id VARCHAR(36) PRIMARY KEY"
                ")"
            )
        )
        connection.execute(
            text(
                "INSERT INTO users (id, cep) "
                "VALUES ('user-1', '13000-000')"
            )
        )

        context = MigrationContext.configure(connection)
        monkeypatch.setattr(migration, "op", Operations(context))
        migration.upgrade()

        inspector = inspect(connection)
        table_names = inspector.get_table_names()
        user_columns = {column["name"] for column in inspector.get_columns("users")}
        announcement_columns = {
            column["name"]
            for column in inspector.get_columns("trade_announcements")
        }
        migrated_user = connection.execute(
            text("SELECT cep_id FROM users WHERE id = 'user-1'")
        ).scalar_one()
        migrated_location = connection.execute(
            text("SELECT cep FROM locations WHERE cep = '13000000'")
        ).scalar_one()

    assert "locations" in table_names
    assert "cep" not in user_columns
    assert "cep_id" in user_columns
    assert "cep_id" in announcement_columns
    assert migrated_user == "13000000"
    assert migrated_location == "13000000"
