import os
from pydantic import BaseModel

class Settings(BaseModel):
    APP_NAME: str = "RuralCare API (NABHA)"
    API_V1_STR: str = "/api/v1"
    PROJECT_VERSION: str = "1.0.0"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "ruralcare-production-secret-key-2026-pune-rural")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    CORS_ORIGINS: list[str] = ["*"]

settings = Settings()
