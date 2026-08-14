from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from sse_starlette.sse import EventSourceResponse
from typing import List
import logging

from ..config.settings import settings
from ..ai.providers.openai_provider import OpenAIProvider
from ..ai.providers.anthropic_provider import AnthropicProvider
from ..ai.providers.mock_provider import MockProvider
from ..ai.gateway.model_registry import registry
from ..ai.gateway.gateway import gateway
from ..ai.providers.base import ChatRequest, ChatMessage
from ..middleware.security import security_headers_middleware
from ..core.exceptions import NorlexException

# Setup
limiter = Limiter(key_func=get_remote_address, default_limits=[f"{settings.rate_limit_per_minute}/minute"])
app = FastAPI(
    title="NORLEX API",
    description="NORLEX Unified AI Platform - Backend Gateway",
    version="1.0.0",
    docs_url="/docs" if not settings.is_prod else None,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS - strict in production
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    return await security_headers_middleware(request, call_next)

# Exception handler - sanitizes errors, no stack traces to client
@app.exception_handler(NorlexException)
async def norlex_exception_handler(request: Request, exc: NorlexException):
    return JSONResponse(status_code=exc.status_code, content={"code": exc.code, "message": exc.message})

# Register providers - foundation
openai_provider = OpenAIProvider()
anthropic_provider = AnthropicProvider()
mock_provider = MockProvider()

registry.register_provider(openai_provider)
registry.register_provider(anthropic_provider)
if settings.is_dev:
    registry.register_provider(mock_provider)

# Routes
@app.get("/")
async def root():
    return {"name": "NORLEX API", "version": "1.0.0", "env": settings.env}

@app.get(f"{settings.api_prefix}/health")
async def health():
    return {"status": "ok", "providers": [{"id": p.provider_id, "configured": p.is_configured()} for p in registry.list_providers()]}

@app.get(f"{settings.api_prefix}/models")
async def list_models():
    models = registry.list_all_models()
    return {"models": [m.model_dump() for m in models]}

@app.post(f"{settings.api_prefix}/chat/completions")
@limiter.limit(f"{settings.default_requests_per_minute}/minute")
async def chat_completions(request: Request, body: ChatRequest):
    # Cost protection check
    from ..ai.policies.cost_protection import cost_protection
    user_id = body.user_id or get_remote_address(request)
    if not cost_protection.check_and_record(user_id, body.max_tokens or 100):
        raise NorlexException(429, "rate_limited", "Rate or token limit exceeded")
    
    try:
        response = await gateway.chat_completion(body)
        return {"content": response, "model": body.model}
    except NorlexException:
        raise
    except Exception as e:
        logging.error(f"chat_completions error: {e}")
        raise NorlexException(500, "internal_error", "Internal server error")

@app.post(f"{settings.api_prefix}/chat/stream")
async def chat_stream(request: Request, body: ChatRequest):
    async def event_generator():
        try:
            async for chunk in gateway.chat_stream(body):
                # SSE format
                event_type = chunk.type
                data = chunk.model_dump_json()
                yield {"event": event_type, "data": data}
        except Exception as e:
            yield {"event": "error", "data": f'{{"code": "internal_error", "message": "Stream error"}}'}
    
    return EventSourceResponse(event_generator())

# Conversations CRUD - foundation
@app.get(f"{settings.api_prefix}/conversations")
async def list_conversations():
    # Foundation - would query DB
    return {"conversations": []}

@app.post(f"{settings.api_prefix}/conversations")
async def create_conversation():
    return {"id": "new_id", "title": "New Chat"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=settings.host, port=settings.port)
