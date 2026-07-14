"""add authentication fields and sessions"""
from alembic import op
import sqlalchemy as sa

revision = "20260711_01"
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    # The project predates Alembic. Bootstrap a completely empty database from
    # current metadata; existing installations continue through the alterations.
    if "users" not in sa.inspect(op.get_bind()).get_table_names():
        from app.core.database import Base
        from app.domain.books import models as _books
        from app.domain.locations import models as _locations
        from app.domain.announcements import models as _announcements
        from app.domain.users import models as _users
        Base.metadata.create_all(bind=op.get_bind())
        return
    for name, column in [
        ("username_normalized", sa.Column("username_normalized", sa.String(), nullable=True)),
        ("email_normalized", sa.Column("email_normalized", sa.String(), nullable=True)),
        ("password_hash", sa.Column("password_hash", sa.String(), nullable=True)),
        ("birth_date", sa.Column("birth_date", sa.Date(), nullable=True)),
        ("created_at", sa.Column("created_at", sa.DateTime(), server_default=sa.func.now(), nullable=False)),
        ("updated_at", sa.Column("updated_at", sa.DateTime(), server_default=sa.func.now(), nullable=False)),
    ]: op.add_column("users", column)
    op.execute("UPDATE users SET email_normalized = LOWER(email), username_normalized = LOWER(username)")
    op.create_unique_constraint("uq_users_email_normalized", "users", ["email_normalized"])
    op.create_unique_constraint("uq_users_username_normalized", "users", ["username_normalized"])
    op.create_table("auth_sessions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("refresh_token_hash", sa.String(64), nullable=False, unique=True),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("revoked_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now(), nullable=False))

def downgrade():
    op.drop_table("auth_sessions")
    for constraint in ["uq_users_username_normalized", "uq_users_email_normalized"]:
        op.drop_constraint(constraint, "users", type_="unique")
    for name in ["updated_at", "created_at", "birth_date", "password_hash", "email_normalized", "username_normalized"]:
        op.drop_column("users", name)
