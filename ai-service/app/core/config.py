"""
Application configuration using Pydantic Settings.
All values are read from environment variables or .env file.
"""

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    # ── Application ─────────────────────────────────────────────────────────
    app_name: str = "DVC Guide AI Service"
    app_version: str = "0.1.0"
    environment: str = "development"
    debug: bool = True

    # ── Server ────────────────────────────────────────────────────────────────
    host: str = "0.0.0.0"
    port: int = 8000

    # ── CORS ──────────────────────────────────────────────────────────────────
    allowed_origins: list[str] = ["http://localhost:8080", "http://10.0.2.2:8080"]

    # ── Ollama ──────────────────────────────────────────────────────
    ollama_base_url: str = "http://localhost:11434"
    ollama_model: str = Field(default="", max_length=50)
    ollama_timeout_seconds: int = Field(default=45, ge=1)
    ollama_embed_model: str = "nomic-embed-text"

    # ── Vector Database (Future) ──────────────────────────────────────────────
    vector_db_url: str = "http://localhost:6333"  # Qdrant default
    vector_db_collection: str = "dvc_procedures"

    # ── Spring Boot Backend ────────────────────────────────────────────────────
    backend_url: str = "http://localhost:8080"



settings = Settings()
