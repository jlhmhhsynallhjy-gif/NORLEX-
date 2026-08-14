
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import MetaData
from ..config.settings import settings
import logging

logger = logging.getLogger("database")

# Use async engine
# PostgreSQL: postgresql+asyncpg://user:pass@host/db
# SQLite fallback: sqlite+aiosqlite:///./norlex.db

def get_database_url() -> str:
    url = settings.database_url
    # Convert to async URL
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+asyncpg://", 1)
    if url.startswith("sqlite:///"):
        return url.replace("sqlite:///", "sqlite+aiosqlite:///", 1)
    if "postgresql+asyncpg" in url or "sqlite+aiosqlite" in url:
        return url
    # Default to sqlite for dev
    return "sqlite+aiosqlite:///./norlex.db"

DATABASE_URL = get_database_url()

engine = create_async_engine(
    DATABASE_URL,
    echo=settings.is_dev,
    pool_pre_ping=True,
    # For SQLite, need check_same_thread=False handled by aiosqlite
)

AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

class Base(DeclarativeBase):
    metadata = MetaData()

async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

async def init_db():
    # For dev without alembic, create tables
    if "sqlite" in DATABASE_URL:
        from ..models import user, session, conversation, message, usage, file, project
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("Database tables created (SQLite dev mode)")
