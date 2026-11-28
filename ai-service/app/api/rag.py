from fastapi import APIRouter, Header, HTTPException, Request, status, Path
from app.integrations.ollama.client import OllamaUnavailable
from app.schemas.rag_schemas import QueryRequest, QueryResponse, SyncProcedureRequest, SyncProcedureResponse

router = APIRouter(prefix="/api/v1/rag", tags=["RAG"])

@router.put('/procedures/{procedure_id}', response_model=SyncProcedureResponse)
async def sync_procedure(body: SyncProcedureRequest, request: Request, procedure_id: int = Path(gt=0),
                         x_api_key: str | None = Header(default=None)):
    return await request.app.state.rag_service.sync_procedure(procedure_id, body, x_api_key)

@router.post("/query", response_model=QueryResponse)
async def query(
    body: QueryRequest,
    request: Request,
    x_api_key: str | None = Header(default=None),
) -> QueryResponse:
    try:
        return await request.app.state.rag_service.query(body, x_api_key)
    except OllamaUnavailable as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error
