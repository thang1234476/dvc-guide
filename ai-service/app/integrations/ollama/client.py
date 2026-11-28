import os
from typing import Any
import httpx
from pydantic import BaseModel, Field, ValidationError

class OllamaUnavailable(Exception):
    pass

class ChatMessage(BaseModel):
    content: str = Field(min_length=1)

class ChatResponse(BaseModel):
    message: ChatMessage

class OllamaClient:

    def __init__(self, http: httpx.AsyncClient, model: str) -> None:
        self._http = http
        self.model = model

    async def chat(self, messages: list[dict[str, str]], response_schema: dict[str, Any] | None=None) -> str:
        if not self.model:
            raise OllamaUnavailable('Dịch vụ AI chưa được cấu hình mô hình Ollama.')
        payload = {'model': self.model, 'messages': messages, 'stream': False}
        if response_schema is not None:
            payload.update(format=response_schema, options={'temperature': 0.1, 'num_predict': 768})
        else:
            payload.update(think=False, options={'temperature': 0, 'num_ctx': int(os.getenv('TTHC_NUM_CTX', '8192')), 'num_predict': int(os.getenv('TTHC_NUM_PREDICT', '900'))})
        try:
            response = await self._http.post('/api/chat', json=payload)
            response.raise_for_status()
            answer = ChatResponse.model_validate_json(response.content).message.content
            if os.getenv("TTHC_DEBUG") == "1":
                import logging
                details = response.json()
                stats = {k: details.get(k) for k in ("done_reason", "prompt_eval_count", "eval_count")}
                for k in ("total_duration", "load_duration", "prompt_eval_duration", "eval_duration"):
                    stats[k.replace("_duration", "_s")] = round((details.get(k) or 0) / 1e9, 2)
                stats["options"] = payload.get("options")
                stats["thinking_chars"] = len(details.get("message", {}).get("thinking") or "")
                logger = logging.getLogger("tthc")
                logger.info("ollama_debug_stats=%s", stats)
                logger.info("ollama_debug_answer=%r", details.get("message", {}).get("content"))
            return answer
        except (httpx.HTTPError, ValidationError) as error:
            raise OllamaUnavailable('Không nhận được phản hồi hợp lệ từ Ollama.') from error

    async def health(self):
        try:
            response = await self._http.get('/api/tags', timeout=3)
            response.raise_for_status()
            names = {m.get('name') for m in response.json().get('models', [])}
            name = self.model if ':' in self.model else self.model + ':latest'
            return {'ollama': True, 'model_available': name in names}
        except (httpx.HTTPError, ValueError):
            return {'ollama': False, 'model_available': False}
