import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.database.session import engine, SessionLocal
from app.database.base import Base
import app.models  # load all models
from app.services.achievements import AchievementService

from app.api.v1.sessions import router as sessions_router
from app.api.v1.dashboard import router as dashboard_router
from app.api.v1.achievements import router as achievements_router
from app.api.v1.difficulty import router as difficulty_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("focus_backend")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: create tables and seed data
    logger.info("Initializing database tables...")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        AchievementService.seed_achievements(db)
        logger.info("Database initialized and achievements seeded.")
    finally:
        db.close()
    yield
    # Shutdown
    logger.info("Shutting down FocusFlow backend...")

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan,
)

# CORS configuration for iOS / Web / Local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(sessions_router, prefix=settings.API_V1_STR)
app.include_router(dashboard_router, prefix=settings.API_V1_STR)
app.include_router(achievements_router, prefix=settings.API_V1_STR)
app.include_router(difficulty_router, prefix=settings.API_V1_STR)

@app.get(f"{settings.API_V1_STR}/health")
def health_check():
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "database": "connected",
    }
