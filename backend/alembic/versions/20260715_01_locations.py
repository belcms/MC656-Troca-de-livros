"""integrate users and announcements with locations"""

import re

from alembic import op
import sqlalchemy as sa


revision = "20260715_01"
down_revision = "20260713_01"
branch_labels = None
depends_on = None


def _table_names() -> set[str]:
    return set(sa.inspect(op.get_bind()).get_table_names())


def _column_names(table_name: str) -> set[str]:
    return {
        column["name"]
        for column in sa.inspect(op.get_bind()).get_columns(table_name)
    }


def _has_location_foreign_key(table_name: str) -> bool:
    return any(
        foreign_key["constrained_columns"] == ["cep_id"]
        and foreign_key["referred_table"] == "locations"
        and foreign_key["referred_columns"] == ["cep"]
        for foreign_key in sa.inspect(op.get_bind()).get_foreign_keys(table_name)
    )


def _has_index(table_name: str, column_name: str) -> bool:
    return any(
        index["column_names"] == [column_name]
        for index in sa.inspect(op.get_bind()).get_indexes(table_name)
    )


def _normalized_cep(value) -> str | None:
    if value is None:
        return None
    clean = re.sub(r"\D", "", str(value))
    return clean if len(clean) == 8 else None


def _ensure_location(cep: str) -> None:
    bind = op.get_bind()
    exists = bind.execute(
        sa.text("SELECT 1 FROM locations WHERE cep = :cep"),
        {"cep": cep},
    ).first()
    if not exists:
        bind.execute(
            sa.text("INSERT INTO locations (cep) VALUES (:cep)"),
            {"cep": cep},
        )


def _backfill_users(old_cep_column_exists: bool) -> None:
    bind = op.get_bind()
    selected_columns = "id, cep_id"
    if old_cep_column_exists:
        selected_columns += ", cep"

    for row in bind.execute(sa.text(f"SELECT {selected_columns} FROM users")).mappings():
        raw_cep = row.get("cep_id") or row.get("cep")
        clean_cep = _normalized_cep(raw_cep)
        if clean_cep is None:
            if row.get("cep_id") is not None:
                bind.execute(
                    sa.text("UPDATE users SET cep_id = NULL WHERE id = :user_id"),
                    {"user_id": row["id"]},
                )
            continue
        _ensure_location(clean_cep)
        bind.execute(
            sa.text("UPDATE users SET cep_id = :cep WHERE id = :user_id"),
            {"cep": clean_cep, "user_id": row["id"]},
        )


def _backfill_announcements() -> None:
    bind = op.get_bind()
    rows = bind.execute(
        sa.text(
            "SELECT id, cep_id FROM trade_announcements "
            "WHERE cep_id IS NOT NULL"
        )
    ).mappings()
    for row in rows:
        clean_cep = _normalized_cep(row["cep_id"])
        if clean_cep is None:
            bind.execute(
                sa.text(
                    "UPDATE trade_announcements SET cep_id = NULL WHERE id = :id"
                ),
                {"id": row["id"]},
            )
            continue
        _ensure_location(clean_cep)
        bind.execute(
            sa.text(
                "UPDATE trade_announcements SET cep_id = :cep WHERE id = :id"
            ),
            {"cep": clean_cep, "id": row["id"]},
        )


def upgrade():
    tables = _table_names()
    if "locations" not in tables:
        op.create_table(
            "locations",
            sa.Column("cep", sa.String(8), primary_key=True),
            sa.Column("city", sa.String(), nullable=True),
            sa.Column("state", sa.String(), nullable=True),
            sa.Column("country", sa.String(), nullable=True),
            sa.Column("district", sa.String(), nullable=True),
            sa.Column("lat", sa.Float(), nullable=True),
            sa.Column("long", sa.Float(), nullable=True),
        )
    else:
        location_columns = _column_names("locations")
        for column_name, column_type in [
            ("city", sa.String()),
            ("state", sa.String()),
            ("country", sa.String()),
            ("district", sa.String()),
            ("lat", sa.Float()),
            ("long", sa.Float()),
        ]:
            if column_name not in location_columns:
                op.add_column(
                    "locations",
                    sa.Column(column_name, column_type, nullable=True),
                )

    user_columns = _column_names("users")
    old_user_cep_exists = "cep" in user_columns
    if "cep_id" not in user_columns:
        op.add_column("users", sa.Column("cep_id", sa.String(8), nullable=True))

    announcement_columns = _column_names("trade_announcements")
    if "cep_id" not in announcement_columns:
        op.add_column(
            "trade_announcements",
            sa.Column("cep_id", sa.String(8), nullable=True),
        )

    _backfill_users(old_user_cep_exists)
    _backfill_announcements()

    if not _has_location_foreign_key("users"):
        with op.batch_alter_table("users") as batch_op:
            batch_op.create_foreign_key(
                "fk_users_cep_id_locations",
                "locations",
                ["cep_id"],
                ["cep"],
            )
    if not _has_index("users", "cep_id"):
        op.create_index("ix_users_cep_id", "users", ["cep_id"])

    if not _has_location_foreign_key("trade_announcements"):
        with op.batch_alter_table("trade_announcements") as batch_op:
            batch_op.create_foreign_key(
                "fk_trade_announcements_cep_id_locations",
                "locations",
                ["cep_id"],
                ["cep"],
            )
    if not _has_index("trade_announcements", "cep_id"):
        op.create_index(
            "ix_trade_announcements_cep_id",
            "trade_announcements",
            ["cep_id"],
        )

    if old_user_cep_exists:
        with op.batch_alter_table("users") as batch_op:
            batch_op.drop_column("cep")


def downgrade():
    user_columns = _column_names("users")
    if "cep" not in user_columns:
        op.add_column("users", sa.Column("cep", sa.String(), nullable=True))
    op.execute("UPDATE users SET cep = cep_id WHERE cep_id IS NOT NULL")

    for table_name, constraint_name, index_name in [
        ("users", "fk_users_cep_id_locations", "ix_users_cep_id"),
        (
            "trade_announcements",
            "fk_trade_announcements_cep_id_locations",
            "ix_trade_announcements_cep_id",
        ),
    ]:
        foreign_keys = sa.inspect(op.get_bind()).get_foreign_keys(table_name)
        if any(foreign_key["name"] == constraint_name for foreign_key in foreign_keys):
            with op.batch_alter_table(table_name) as batch_op:
                batch_op.drop_constraint(constraint_name, type_="foreignkey")
        indexes = sa.inspect(op.get_bind()).get_indexes(table_name)
        if any(index["name"] == index_name for index in indexes):
            op.drop_index(index_name, table_name=table_name)
