"""remove legacy Google authentication columns"""

from alembic import op
import sqlalchemy as sa


revision = "20260713_01"
down_revision = "20260711_01"
branch_labels = None
depends_on = None


def upgrade():
    inspector = sa.inspect(op.get_bind())
    columns = {column["name"] for column in inspector.get_columns("users")}
    if "google_subject" in columns:
        unique_constraint_found = False
        for constraint in inspector.get_unique_constraints("users"):
            if constraint["column_names"] == ["google_subject"] and constraint["name"]:
                with op.batch_alter_table("users") as batch_op:
                    batch_op.drop_constraint(constraint["name"], type_="unique")
                unique_constraint_found = True
        if not unique_constraint_found:
            for index in inspector.get_indexes("users"):
                if index["column_names"] == ["google_subject"] and index["name"]:
                    with op.batch_alter_table("users") as batch_op:
                        batch_op.drop_index(index["name"])
        with op.batch_alter_table("users") as batch_op:
            batch_op.drop_column("google_subject")
    if "onboarding_complete" in columns:
        with op.batch_alter_table("users") as batch_op:
            batch_op.drop_column("onboarding_complete")


def downgrade():
    # The removed external-auth state is intentionally not recreated.
    pass
