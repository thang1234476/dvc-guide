"""
Ollama client integration placeholder.

Ollama is a local LLM runtime for running open-source models like:
- Qwen2 (recommended for Vietnamese language support)
- LLaMA 3
- Mistral

NOT YET IMPLEMENTED.

Future implementation will use the `ollama` Python library or direct HTTP calls
to the Ollama REST API (default: http://localhost:11434).
"""

# from ollama import AsyncClient
#
# class OllamaClient:
#     def __init__(self, base_url: str, model: str, embed_model: str):
#         self.client = AsyncClient(host=base_url)
#         self.model = model
#         self.embed_model = embed_model
#
#     async def embed(self, text: str) -> list[float]:
#         """Generate text embedding for vector search."""
#         response = await self.client.embeddings(model=self.embed_model, prompt=text)
#         return response.embedding
#
#     async def generate(self, prompt: str, context: str) -> str:
#         """Generate answer using LLM with RAG context."""
#         response = await self.client.generate(
#             model=self.model,
#             prompt=f"Context:\n{context}\n\nQuestion: {prompt}\nAnswer:",
#             stream=False,
#         )
#         return response.response
