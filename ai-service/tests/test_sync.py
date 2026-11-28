import json
from copy import deepcopy

import httpx
import pytest

from app.main import app
from app.integrations.ollama.client import OllamaClient
from app.services.rag_service import RagService
from app.services.retrieval import Retriever
from .conftest import embed, tokens


def payload(version=1, code='TEST-001', active=True, fee=100):
    return {'version': version, 'code': code, 'active': active, 'procedure': {
        'ma_thu_tuc': code, 'ten': 'Thủ tục kiểm thử', 'linh_vuc': [], 'trinh_tu': [],
        'ho_so': [{'ten': 'Đơn đăng ký', 'nhom': 'nop', 'mau_don': []}],
        'cach_thuc': [{'hinh_thuc': 'truc_tiep', 'thoi_han': {'so': None, 'don_vi': None, 'goc': None},
                      'le_phi': [{'so_tien': fee, 'tien_te': 'VND', 'mien_phi': False}]}],
    } if active else None}


@pytest.mark.asyncio
async def test_requires_private_key_for_queries_and_sync(client):
    for path, method, body in [('/api/v1/rag/procedures/1', 'PUT', payload()),
                                ('/api/v1/rag/query', 'POST', {'question': 'Cần gì?'})]:
        response = await client.request(method, path, json=body, headers={'X-API-Key': 'wrong'})
        assert response.status_code == 401


@pytest.mark.asyncio
async def test_sync_updates_renames_deletes_and_persists_tombstones(client, retriever):
    path = '/api/v1/rag/procedures/1'
    response = await client.put(path, json=payload())
    assert response.status_code == 200
    assert response.json()['chunk_count'] > 0
    assert json.load(open(retriever.data_path)) == [], 'Original clean.json is not overwritten'
    assert (await client.put(path, json=payload())).json()['applied'] is False
    assert (await client.put(path, json=payload(fee=200))).status_code == 409
    assert (await client.put(path, json=payload(2, 'RENAMED', fee=200))).status_code == 200
    assert set(retriever.state.by_id) == {'RENAMED'}
    assert any('200' in text for text in retriever.state.texts)
    assert (await client.put(path, json=payload(3, 'RENAMED', active=False))).status_code == 200
    assert not retriever.state.by_id
    restored = Retriever(retriever.data_path, retriever.cache_dir, embed_fn=embed,
                         rerank_fn=retriever.rerank, tok_fn=tokens, runtime_path=retriever.runtime_path)
    restored.apply_sync(1, payload(2, 'RENAMED'))
    assert not restored.state.by_id, 'An old retry must not resurrect a deleted procedure after restart'
    assert restored.versions['1']['version'] == 3


@pytest.mark.asyncio
async def test_does_not_serve_old_or_unknown_database_versions(client, retriever):
    await client.put('/api/v1/rag/procedures/1', json=payload())
    def generate(request):
        body = json.loads(request.content)
        assert 'Đơn đăng ký' in body['messages'][-1]['content']
        return httpx.Response(200, json={'message': {'content': 'Cần Đơn đăng ký.\nNguồn: Thủ tục kiểm thử'}})
    async with httpx.AsyncClient(base_url='http://ollama', transport=httpx.MockTransport(generate)) as upstream:
        app.state.rag_service = RagService(OllamaClient(upstream, 'test-model'), retriever=retriever)
        body = {'question': 'Cần giấy tờ gì?', 'procedure_id': 'TEST-001',
                'allowed_procedures': [{'procedure_id': 1, 'code': 'TEST-001', 'version': 1}]}
        response = await client.post('/api/v1/rag/query', json=body)
        assert response.status_code == 200
        assert response.json()['how'] == 'answered'
        assert response.json()['source_versions'] == body['allowed_procedures']
        body['allowed_procedures'][0]['version'] = 2
        response = await client.post('/api/v1/rag/query', json=body)
        assert response.json()['source_codes'] == []
        assert response.json()['how'] == 'gate'
        body['allowed_procedures'] = []
        assert (await client.post('/api/v1/rag/query', json=body)).json()['source_codes'] == []


def test_failed_snapshot_write_keeps_old_state_and_can_retry(retriever, monkeypatch):
    retriever.apply_sync(1, payload())
    original = deepcopy(retriever.state.by_id)
    import os
    replace = os.replace
    def fail(source, target):
        if target == retriever.runtime_path:
            raise OSError('Simulated storage failure')
        return replace(source, target)
    monkeypatch.setattr(os, 'replace', fail)
    with pytest.raises(OSError):
        retriever.apply_sync(1, payload(2, fee=200))
    assert retriever.state.by_id == original
    assert retriever.versions['1']['version'] == 1
    monkeypatch.setattr(os, 'replace', replace)
    assert retriever.apply_sync(1, payload(2, fee=200))['version'] == 2


def test_same_code_cannot_overwrite_a_different_database_id(retriever):
    retriever.apply_sync(1, payload())
    with pytest.raises(ValueError):
        retriever.apply_sync(2, payload())
    retriever.apply_sync(2, payload(active=False))
    assert 'TEST-001' in retriever.state.by_id
