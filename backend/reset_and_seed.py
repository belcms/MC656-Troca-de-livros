import asyncio
import sys
import os
from sqlalchemy import text

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import get_db, engine
from app.domain.announcements.services import create_dummy_data

async def main():
    print("Dropping tables with cascade...")
    with engine.begin() as conn:
        conn.execute(text("TRUNCATE TABLE users, locations, books, editions, trade_announcements, photo_trade_announcements, wishlist, auth_sessions, offer, offered_announcements CASCADE;"))
    
    print("Connecting to the database and populating dummy data...")
    db_gen = get_db()
    db = next(db_gen)
    try:
        result = await create_dummy_data(db)
        print("Result:", result)
    except Exception as e:
        print("An error occurred:", e)
    finally:
        try:
            next(db_gen)
        except StopIteration:
            pass

if __name__ == "__main__":
    asyncio.run(main())
