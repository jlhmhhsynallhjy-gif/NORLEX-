# NORLEX Backend - AI Gateway + API

## Technology Choice: Python + FastAPI

### Why FastAPI for NORLEX long-term?

**Compared:**
- Node.js + TypeScript: Great for real-time, JS ecosystem, but AI ecosystem (token counting, embeddings, evals) is Python-first. OpenAI/Anthropic official Python SDKs are more mature for advanced features.
- Dart Server: Code sharing with Flutter attractive, but AI ecosystem immature, few production adapters, weak observability libs.
- Python + FastAPI: Winner for AI Gateway.

**Reasons:**
1. **AI Native:** Python is lingua franca of AI. tiktoken, langchain, anthropic, openai, google-generativeai all Python-first. Token counting, cost calculation, embeddings - all best in Python.
2. **Streaming:** FastAPI + sse-starlette gives native SSE streaming, perfect for chat completions (start/chunk/tool_event/completed).
3. **Validation:** Pydantic v2 is strongest validation for API contracts, shared with Flutter via OpenAPI generation.
4. **Security:** SlowAPI for rate limiting, passlib for secure password hashing, python-jose for JWT - production hardened.
5. **Performance:** Async, ASGI, handles thousands of concurrent SSE connections, provider timeout/retry via httpx.
6. **Observability:** Structured logging, request ID middleware, easy integration with OpenTelemetry later.
7. **Future Proof:** Easy to add vector DB (pgvector), queue (Celery/RQ), and ML services - all Python.

### Architecture
```
Flutter App -> NORLEX API (FastAPI) -> Auth -> AI Gateway -> Provider Adapter -> AI Provider
```

### Quick Start
```bash
cp .env.example .env
# Edit .env with real secrets (never commit)
pip install -r requirements.txt
uvicorn src.server.main:app --reload --port 8000
```

### API Docs
- http://localhost:8000/docs (Swagger)
- http://localhost:8000/redoc

### Security
- No secrets in Flutter - all provider keys in backend .env only
- JWT access (15min) + refresh (7 days)
- Rate limiting per user/IP
- CORS, secure headers, request size limits
- Error sanitization - no stack traces to client

### Streaming Protocol (SSE)
```
event: start
data: {"conversation_id": "...", "model": "..."}

event: chunk
data: {"content": "Hello", "index": 0}

event: tool_event
data: {"tool": "search", "status": "running"}

event: completed
data: {"finish_reason": "stop", "usage": {...}}

event: error
data: {"code": "provider_unavailable", "message": "..."}
```
