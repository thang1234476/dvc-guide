from typing import Any
from typing import Annotated, Literal
from pydantic import BaseModel, ConfigDict, Field, StringConstraints, model_validator
ProcedureCode = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=50)]
AnswerText = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=12000)]

class Source(BaseModel):
    model_config = ConfigDict(extra='forbid')
    procedure_id: int = Field(gt=0)
    code: ProcedureCode
    title: str = Field(min_length=1, max_length=1000)
    content: str = Field(min_length=1, max_length=6000)
    version: int | None = Field(default=None, gt=0)

class SourceVersion(BaseModel):
    model_config = ConfigDict(extra='forbid')
    procedure_id: int = Field(gt=0)
    code: ProcedureCode
    version: int = Field(gt=0)

class SyncProcedureRequest(BaseModel):
    model_config = ConfigDict(extra='forbid')
    version: int = Field(gt=0)
    code: ProcedureCode
    active: bool
    procedure: dict[str, Any] | None = None

    @model_validator(mode='after')
    def consistent_payload(self):
        if self.active and (not self.procedure or self.procedure.get('ma_thu_tuc') != self.code):
            raise ValueError('Thủ tục đang áp dụng cần dữ liệu có mã khớp với code.')
        return self

class SyncProcedureResponse(BaseModel):
    procedure_id: int
    version: int
    code: str
    active: bool
    chunk_count: int
    applied: bool

class ChatTurn(BaseModel):
    model_config = ConfigDict(extra='forbid')
    role: Literal['user', 'assistant']
    content: str = Field(min_length=1, max_length=12000)
    sources: list[dict[str, Any] | str] = Field(default_factory=list)

class QueryRequest(BaseModel):
    model_config = ConfigDict(extra='forbid')
    question: Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=2000)]
    sources: list[Source] = Field(default_factory=list, max_length=3)
    history: list[ChatTurn] = Field(default_factory=list, max_length=6)
    procedure_id: Annotated[str, StringConstraints(strip_whitespace=True, max_length=50)] = ''
    allowed_procedures: list[SourceVersion] | None = Field(default=None, max_length=10000)

class GeneratedAnswer(BaseModel):
    model_config = ConfigDict(extra='forbid')
    answer: AnswerText
    source_codes: list[ProcedureCode] = Field(max_length=3)

class QueryResponse(GeneratedAnswer):
    how: Literal['answered', 'gate', 'guard']
    latency_ms: int = Field(ge=0)
    model: str | None = Field(default=None, max_length=50)
    status: Literal['answered', 'need_choice', 'no_info'] = 'no_info'
    flow: str | None = None
    sources: list[dict[str, str]] = Field(default_factory=list)
    forms: list[dict[str, str]] = Field(default_factory=list)
    options: list[dict[str, str]] = Field(default_factory=list)
    related: list[dict[str, str]] = Field(default_factory=list)
    followup: bool = False
    chosen: bool = False
    pinned: bool = False
    top_score: float | None = None
    source_versions: list[SourceVersion] = Field(default_factory=list)
