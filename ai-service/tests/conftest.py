import json
import re

import httpx
import numpy as np
import pytest
import pytest_asyncio

from app.integrations.ollama.client import OllamaClient
from app.main import app
from app.services.rag_service import RagService
from app.services.retrieval import Retriever


def tokens(text):
    return re.findall(r'\w+', text.lower())


def embed(texts):
    import hashlib
    result = np.zeros((len(texts), 32), dtype='float32')
    for i, text in enumerate(texts):
        for token in tokens(text):
            result[i, hashlib.md5(token.encode()).digest()[0] % 32] += 1
        result[i] /= max(float(np.linalg.norm(result[i])), 1)
    return result


@pytest.fixture
def retriever(tmp_path, monkeypatch):
    data = tmp_path / 'data'
    data.mkdir()
    (data / 'clean.json').write_text('[]')
    (data / 'gate.json').write_text(json.dumps({'TAU': .1}))
    monkeypatch.setenv('TTHC_ROOT', str(tmp_path))
    monkeypatch.setenv('TTHC_API_KEYS', 'test-private-key')
    return Retriever(str(data / 'clean.json'), str(tmp_path / 'cache'), embed_fn=embed,
                     rerank_fn=lambda query, texts: np.array([len(set(tokens(query)) & set(tokens(t))) + .5 for t in texts]),
                     tok_fn=tokens, runtime_path=str(tmp_path / 'runtime/state.json'), log=lambda message: None)


@pytest_asyncio.fixture
async def client(retriever):
    async with httpx.AsyncClient(base_url='http://ollama', transport=httpx.MockTransport(
            lambda request: httpx.Response(503))) as upstream:
        app.state.rag_service = RagService(OllamaClient(upstream, ''), retriever=retriever)
        async with httpx.AsyncClient(base_url='http://app', transport=httpx.ASGITransport(app),
                                     headers={'X-API-Key': 'test-private-key'}) as client:
            yield client
