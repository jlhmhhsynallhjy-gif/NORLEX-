# NORLEX Phase 3 - AI Gateway + Backend Architecture

## Technology Choice: Python + FastAPI

### Comparison

| Criteria | Node.js + TS | Python FastAPI | Dart Server |
|----------|--------------|----------------|-------------|
| AI Ecosystem | Good (OpenAI TS SDK) | Excellent (Python-first: tiktoken, langchain, anthropic) | Poor |
| Streaming | Good (SSE) | Excellent (sse-starlette) | Basic |
| Validation | Zod | Pydantic v2 (best) | Limited |
| Security libs | Good | Excellent (slowapi, passlib, jose) | Basic |
| Performance | Very High | High (ASGI) | Medium |
| Hiring/Scale | Easy | Easy (AI talent) | Hard |
| Code Sharing with Flutter | No | No | Yes, but immature |

**Decision: Python + FastAPI** - Best for AI Gateway long-term, despite Node being also strong. Python is lingua franca of AI, with best token counting, cost calc, and provider SDKs.

## Backend Structure
```
backend/
├── src/
│   ├── config/settings.py - Env-based config, no secrets in code
│   ├── core/ - exceptions, logging (structured, no secrets)
│   ├── auth/ - JWT access (15min) + refresh (7d), bcrypt
│   ├── ai/
│   │   ├── models/capabilities.py - ProviderCapability, ModelInfo
│   │   ├── providers/base.py - AIProviderAdapter abstract
│   │   ├── providers/openai_provider.py, anthropic_provider.py, mock_provider.py
│   │   ├── gateway/gateway.py - routes to provider based on model_id
│   │   ├── gateway/model_registry.py - central registry
│   │   └── policies/cost_protection.py - per-user daily tokens + per-minute limits
│   ├── middleware/security.py - request ID, secure headers, audit log
│   └── server/main.py - FastAPI app with CORS, rate limiting, SSE endpoints
├── tests/
├── .env.example
└── requirements.txt
```

## API Contract

### Models
GET /api/v1/models -> {models: [ModelInfo]}

### Chat
POST /api/v1/chat/completions -> {content, model}
POST /api/v1/chat/stream -> SSE stream:
  event: start
  event: chunk {content, index}
  event: tool_event {tool, status}
  event: completed {finish_reason, usage}
  event: error {code, message}

### Conversations (foundation)
GET /api/v1/conversations
POST /api/v1/conversations
GET /api/v1/conversations/:id
DELETE /api/v1/conversations/:id

## Streaming Architecture

**Protocol: SSE (Server-Sent Events)**
- Why SSE not WebSocket? SSE is simpler for AI chat (server->client stream only), works with HTTP/2, auto-reconnect, easier to proxy, no need for bidirectional for chat.
- WebSocket would be overkill for chat completions; SSE is standard for OpenAI/Anthropic streaming.
- Future: WebSocket can be added for real-time collaboration features.

**Flow:**
Flutter -> POST /chat/stream (with messages, model)
Backend -> gateway.chat_stream() -> provider.chat_stream() -> yields ChatChunk
Backend -> EventSourceResponse -> SSE events to Flutter
Flutter -> Dio with ResponseType.stream parses SSE, updates UI per chunk

**Aggregation:**
accumulated = chunk1 + chunk2 + chunk3 (preserved in ChatRepositoryImpl)

## Authentication Architecture

- User: id, email, hashed password (bcrypt), full_name, is_active, created_at
- Session: access token (15 min) + refresh token (7 days)
- Token storage: access in memory (Flutter), refresh in SecureStorage
- Refresh strategy: POST /auth/refresh with refresh_token -> new access
- Revocation: refresh token stored in DB with expiry, can be revoked
- Passwords: bcrypt with salt, never logged

## Security

- Rate limiting: slowapi, 60 req/min default, 20 req/min per user for chat
- Input validation: Pydantic models, max request size 10MB
- Secure headers: X-Content-Type-Options, X-Frame-Options, HSTS
- CORS: configurable origins, strict in prod
- Secret management: .env file, never in code, .env.example has placeholders
- Error sanitization: NorlexException returns code+message only, no stack traces
- Audit logging: structured JSON logs with request_id, no secrets
- Provider timeout: 60s, max retries 2 with exponential backoff
- Abuse protection: cost_protection checks daily token limit + per-minute

## Cost Protection Foundation

- Per-user daily token limit: 100k default
- Per-user requests per minute: 20
- Max tokens per request: 4096
- Provider timeout: 60s
- All tracked in CostProtection class (in-memory for foundation, will move to Redis/DB)

## Provider Failover (Policy-based, not random)

- Config: ENABLE_FAILOVER=false, FAILOVER_ORDER=openai,anthropic,google
- Future: If provider A fails, gateway will try B based on policy, not random
- Currently disabled - will be enabled after observability

## Database Choice

- **PostgreSQL** for production (via asyncpg + SQLAlchemy)
- Why: Best for long-term NORLEX (Users, Conversations, Messages, Projects, Files, Tasks, Usage, Subscriptions)
- Supports pgvector for future semantic search/memory
- Supports JSONB for metadata
- For local dev: SQLite via aiosqlite (DATABASE_URL sqlite:///./norlex.db)
- Drift remains Flutter local DB only

## Flutter Integration

- New: backend_api_client.dart points to backend URL (from EnvConfig.apiBaseUrl)
- BackendApi.getModels() fetches models from backend
- BackendChatRepository: hybrid - tries backend first, falls back to local gateway if backend unavailable
- Keeps offline-first: saves user message locally before backend call
- No breaking change to Chat UI or Domain

## Environment Separation

- development: http://localhost:8000/api/v1, mock provider enabled, docs enabled
- staging: https://staging-api.norlex.app/api/v1
- production: https://api.norlex.app/api/v1, docs disabled, strict CORS
- .env.example has no real secrets

## Known Limitations

- Backend requires Python 3.9+ and PostgreSQL (or SQLite for dev)
- Real OpenAI/Anthropic calls need real API keys in backend .env - not configured in this foundation
- Mock provider only for dev testing streaming infra
- Cost protection in-memory - needs Redis for multi-instance
- No user DB yet - auth models are foundation, tables not created (next phase will add Alembic migrations)
