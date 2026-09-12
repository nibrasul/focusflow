import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "FocusFlow Concentration & Attention Engine"
    API_V1_STR: str = "/api/v1"
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        f"postgresql://{os.getenv('USER', 'postgres')}@localhost:5432/focus_training_db"
    )
    
    # Adaptive Difficulty Parameters
    MIN_DIFFICULTY: float = 1.0
    MAX_DIFFICULTY: float = 10.0
    DIFFICULTY_STEP: float = 0.5

    model_config = {
        "env_file": ".env",
        "case_sensitive": True,
        "extra": "ignore",
    }

settings = Settings()
