"""
Placeholder for RAG service implementation.

This service will implement the Retrieval-Augmented Generation pipeline:
1. Embed the user query using an embedding model
2. Search the vector database for relevant document chunks
3. Rerank results for better relevance
4. Pass context + query to Ollama LLM for answer generation
5. Return the answer with source citations

NOT YET IMPLEMENTED.
"""

# Future implementation example:
#
# from app.integrations.ollama.client import OllamaClient
# from app.schemas.rag_schemas import QueryRequest, QueryResponse
#
# class RagService:
#     def __init__(self, ollama: OllamaClient, vector_db):
#         self.ollama = ollama
#         self.vector_db = vector_db
#
#     async def query(self, request: QueryRequest) -> QueryResponse:
#         # 1. Embed query
#         # 2. Retrieve from vector DB
#         # 3. Rerank
#         # 4. Generate
#         raise NotImplementedError("RAG pipeline not yet implemented")
