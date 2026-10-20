from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from config import settings

engine = create_engine(settings.database_url)
SessionLocal = sessionmaker(engine)


def get_db():
    with SessionLocal() as session:
        yield session
