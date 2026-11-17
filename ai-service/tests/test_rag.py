import json
from contextlib import asynccontextmanager

import httpx
import pytest

from app.core.config import settings
from app.integrations.ollama.client import OllamaClient
from app.main import app
from app.services.rag_service import RagService


SOURCE = {
    "procedure_id": 1,
    "code": "DVC-001",
    "title": "Thủ tục thử",
    "content": "Giấy tờ: Đơn đăng ký.",
}


@asynccontextmanager
async def api_client():
    async with app.router.lifespan_context(app):
        async with httpx.AsyncClient(base_url="http://app", transport=httpx.ASGITransport(app)) as client:
            yield client


@pytest.mark.asyncio
async def test_query_without_sources_returns_gate():
    async with api_client() as client:
        response = await client.post("/api/v1/rag/query", json={"question": "Cần giấy tờ gì?"})
        assert response.status_code == 200
        assert response.json()["how"] == "gate"
        assert response.json()["source_codes"] == []
        invalid = await client.post("/api/v1/rag/query", json={"question": "  "})
        assert invalid.status_code == 422


@pytest.mark.asyncio
async def test_query_with_sources_and_disabled_model_returns_503(monkeypatch):
    monkeypatch.setattr(settings, "ollama_model", "")
    async with api_client() as client:
        response = await client.post("/api/v1/rag/query", json={"question": "Cần giấy tờ gì?", "sources": [SOURCE]})
    assert response.status_code == 503


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("code", "expected_status", "expected_codes"),
    [("DVC-001", "answered", ["DVC-001"]), ("OTHER-001", "guard", [])],
)
async def test_ollama_answers_only_reference_supplied_procedures(code, expected_status, expected_codes):
    def ollama(request: httpx.Request) -> httpx.Response:
        assert request.url.path == "/api/chat"
        payload = json.loads(request.content)
        assert payload["stream"] is False
        assert payload["model"] == "test-model"
        assert json.loads(payload["messages"][-1]["content"])["sources"] == [SOURCE]
        return httpx.Response(
            200, json={"message": {"content": json.dumps({"answer": "Cần đơn đăng ký.", "source_codes": [code]})}}
        )

    async with api_client() as client:
        async with httpx.AsyncClient(base_url="http://ollama", transport=httpx.MockTransport(ollama)) as upstream:
            app.state.rag_service = RagService(OllamaClient(upstream, "test-model"))
            response = await client.post("/api/v1/rag/query", json={"question": "Cần giấy tờ gì?", "sources": [SOURCE]})

    assert response.status_code == 200
    assert response.json()["how"] == expected_status
    assert response.json()["source_codes"] == expected_codes
