from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .core.config import settings
from .api.v1.api import api_router

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.PROJECT_VERSION,
    description="Backend microservice for RuralCare (NABHA) - ICMR Triage Engine, Smart Referral Matcher & Offline Reconciliation.",
)

# Enable CORS for Flutter web & mobile access
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount API v1 Router
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/health", tags=["System"])
def health_check():
    return {
        "status": "HEALTHY",
        "service": settings.APP_NAME,
        "version": settings.PROJECT_VERSION,
        "triage_engine": "ICMR_COMPLIANT",
        "smart_matcher": "ACTIVE",
    }

@app.get("/", tags=["System"])
def root():
    return {
        "message": "Welcome to RuralCare Backend API",
        "docs_url": "/docs",
        "api_v1": settings.API_V1_STR,
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
