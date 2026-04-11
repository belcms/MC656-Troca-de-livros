from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Connection URL format: user, password, host, port, and database name.
SQLALCHEMY_DATABASE_URL = "postgresql://admin_livros:senha@localhost:5432/livros_db"

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