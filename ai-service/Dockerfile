FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
COPY data ./data
ENV HF_HOME=/app/cache/huggingface TORCH_HOME=/app/cache/torch TTHC_CACHE=/app/cache/retrieval TTHC_RUNTIME=/app/runtime/rag-state.json
RUN mkdir -p /app/cache /app/runtime /app/logs && chown -R 10001:10001 /app/cache /app/runtime /app/logs
USER 10001:10001
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
