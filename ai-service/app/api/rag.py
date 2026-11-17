from fastapi import APIRouter, HTTPException, Request, status

from app.integrations.ollama.client import OllamaUnavailable
from app.schemas.rag_schemas import QueryRequest, QueryResponse


router = APIRouter(prefix="/api/v1/rag", tags=["RAG"])


@router.post("/query", response_model=QueryResponse)
async def query(body: QueryRequest, request: Request) -> QueryResponse:
    try:
        return await request.app.state.rag_service.query(body)
    except OllamaUnavailable as error:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(error)) from error
