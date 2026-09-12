import os
from pathlib import Path
from pydantic_settings import BaseSettings

BASE_DIR = Path(__file__).resolve().parent.parent.parent
ENV_PATH = BASE_DIR / ".env"

class Settings(BaseSettings):
    PROJECT_NAME: str = "FocusFlow Concentration & Attention Engine"
    API_V1_STR: str = "/api/v1"
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://neondb_owner:npg_3U2VxyIjHYFw@ep-fragrant-salad-axdm6nha-pooler.c-4.us-east-2.aws.neon.tech/neondb?sslmode=require&channel_binding=require"
    )
    
    # Adaptive Difficulty Parameters
    MIN_DIFFICULTY: float = 1.0
    MAX_DIFFICULTY: float = 10.0
    DIFFICULTY_STEP: float = 0.5

    model_config = {
        "env_file": str(ENV_PATH),
        "case_sensitive": True,
        "extra": "ignore",
    }

settings = Settings()
