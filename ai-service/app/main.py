from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.rag import router as rag_router
from app.core.config import settings
from app.integrations.ollama.client import OllamaClient
from app.services.rag_service import RagService


@asynccontextmanager
async def lifespan(app: FastAPI):
    timeout = httpx.Timeout(settings.ollama_timeout_seconds, connect=3)
    async with httpx.AsyncClient(base_url=settings.ollama_base_url, timeout=timeout, trust_env=False) as http:
        app.state.rag_service = RagService(OllamaClient(http, settings.ollama_model.strip()))
        yield


app = FastAPI(
    title=settings.app_name,
    description="Internal API for answering questions from supplied procedure data.",
    version=settings.app_version,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)
app.include_router(rag_router)


@app.get("/api/v1/health", tags=["Health"])
async def health_check():
    return {
        "success": True,
        "message": "AI Service is healthy",
        "data": {
            "status": "UP",
            "service": "dvc-guide-ai-service",
            "version": settings.app_version,
            "rag_enabled": False,
            "ollama_configured": bool(settings.ollama_model.strip()),
        },
    }
