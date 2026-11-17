from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, StringConstraints


ProcedureCode = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=50)]
AnswerText = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=6000)]


class Source(BaseModel):
    model_config = ConfigDict(extra="forbid")

    procedure_id: int = Field(gt=0)
    code: ProcedureCode
    title: str = Field(min_length=1, max_length=1000)
    content: str = Field(min_length=1, max_length=6000)


class ChatTurn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=1000)


class QueryRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    question: Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=2000)]
    sources: list[Source] = Field(default_factory=list, max_length=3)
    history: list[ChatTurn] = Field(default_factory=list, max_length=6)


class GeneratedAnswer(BaseModel):
    model_config = ConfigDict(extra="forbid")

    answer: AnswerText
    source_codes: list[ProcedureCode] = Field(max_length=3)


class QueryResponse(GeneratedAnswer):
    how: Literal["answered", "gate", "guard"]
    latency_ms: int = Field(ge=0)
    model: str | None = Field(default=None, max_length=50)
