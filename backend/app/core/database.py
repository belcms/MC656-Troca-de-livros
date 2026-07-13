from sqlalchemy import create_engine
from sqlalchemy import text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Connection URL format: user, password, host, port, and database name.
SQLALCHEMY_DATABASE_URL = "postgresql+psycopg://admin_books:password@localhost:5433/books_db"
# Create the database engine.
engine = create_engine(SQLALCHEMY_DATABASE_URL)

# Create a database session factory.
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for SQLAlchemy models.
Base = declarative_base()

# Yield a database session and guarantee it is closed.
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def ensure_schema_compatibility():
    """Apply small idempotent schema fixes for databases created before models changed."""
    statements = [
        "ALTER TABLE IF EXISTS locations ADD COLUMN IF NOT EXISTS country VARCHAR",
        "ALTER TABLE IF EXISTS locations ADD COLUMN IF NOT EXISTS district VARCHAR",
        "ALTER TABLE IF EXISTS locations ADD COLUMN IF NOT EXISTS lat FLOAT",
        "ALTER TABLE IF EXISTS locations ADD COLUMN IF NOT EXISTS long FLOAT",
        "ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS cep_id VARCHAR(8)",
        "ALTER TABLE IF EXISTS trade_announcements ADD COLUMN IF NOT EXISTS cep_id VARCHAR(8)",
    ]

    with engine.begin() as connection:
        for statement in statements:
            connection.execute(text(statement))
