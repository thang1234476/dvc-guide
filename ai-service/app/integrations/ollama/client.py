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

    async def chat(self, messages: list[dict[str, str]], response_schema: dict[str, Any]) -> str:
        if not self.model:
            raise OllamaUnavailable("Dịch vụ AI chưa được cấu hình mô hình Ollama.")

        try:
            response = await self._http.post(
                "/api/chat",
                json={
                    "model": self.model,
                    "messages": messages,
                    "format": response_schema,
                    "stream": False,
                    "options": {"temperature": 0.1, "num_predict": 768},
                },
            )
            response.raise_for_status()
            return ChatResponse.model_validate_json(response.content).message.content
        except (httpx.HTTPError, ValidationError) as error:
            raise OllamaUnavailable("Không nhận được phản hồi hợp lệ từ Ollama.") from error
