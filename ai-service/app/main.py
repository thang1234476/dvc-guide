"""
DVC Guide AI Service – Main Application Entry Point.

This FastAPI application serves as the AI/RAG layer for the DVC Guide platform.

Current state: SKELETON ONLY
- Health check endpoint is implemented
- RAG pipeline, embedding, retrieval, and generation are NOT implemented
- Integration with Ollama is NOT implemented

Future implementation will include:
- POST /api/v1/rag/query - Accept user question, return AI-generated answer with citations
- POST /api/v1/rag/ingest - Ingest documents into vector database
- GET /api/v1/rag/collections - List available document collections
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler for startup and shutdown events."""
    # Startup
    print(f"Starting {settings.app_name} v{settings.app_version}")
    print(f"Environment: {settings.environment}")
    # TODO: Initialize vector database connection
    # TODO: Load embedding model
    yield
    # Shutdown
    print("Shutting down AI Service...")
    # TODO: Release resources


app = FastAPI(
    title="DVC Guide AI Service",
    description=(
        "AI/RAG service for DVC Guide – handles document retrieval and generation. "
        "Currently in skeleton mode, RAG pipeline not yet implemented."
    ),
    version="0.1.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)


@app.get("/api/v1/health", tags=["Health"])
async def health_check():
    """Health check endpoint."""
    return {
        "success": True,
        "message": "AI Service is healthy",
        "data": {
            "status": "UP",
            "service": "dvc-guide-ai-service",
            "version": settings.app_version,
            "rag_enabled": False,  # Will be True when RAG pipeline is implemented
        },
    }
