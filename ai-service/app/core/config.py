"""
Application configuration using Pydantic Settings.
All values are read from environment variables or .env file.
"""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
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

    # ── Ollama (Future) ──────────────────────────────────────────────────────
    ollama_base_url: str = "http://localhost:11434"
    ollama_model: str = "qwen2:7b"  # Default model – override via env
    ollama_embed_model: str = "nomic-embed-text"

    # ── Vector Database (Future) ──────────────────────────────────────────────
    vector_db_url: str = "http://localhost:6333"  # Qdrant default
    vector_db_collection: str = "dvc_procedures"

    # ── Spring Boot Backend ────────────────────────────────────────────────────
    backend_url: str = "http://localhost:8080"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


settings = Settings()
