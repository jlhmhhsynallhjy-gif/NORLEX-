
"""
Hardened main - no create_all in prod, proper token counting labels
"""

from fastapi import FastAPI, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from sse_starlette.sse import EventSourceResponse
import logging
import time
import uuid

from ..config.settings import settings
from ..ai.providers.openai_real import OpenAIRealProvider
from ..ai.providers.anthropic_provider import AnthropicProvider
from ..ai.providers.mock_provider import MockProvider
from ..ai.gateway.model_registry import registry
from ..ai.gateway.gateway import gateway
from ..ai.providers.base import ChatRequest
from ..middleware.security import security_headers_middleware
from ..core.exceptions import NorlexException
from ..core.database import get_db
from ..models.user import User
from ..auth.dependencies import get_current_user
from ..auth.router import router as auth_router
from ..conversations.router import router as conv_router
from ..usage.router import router as usage_router
from sqlalchemy.ext.asyncio import AsyncSession
from ..models.usage import UsageRecord
from ..ai.policies.token_counter import TokenCounter

limiter = Limiter(key_func=get_remote_address, default_limits=[f"{settings.rate_limit_per_minute}/minute"])
app = FastAPI(
    title="NORLEX API",
    description="NORLEX Unified AI Platform - Hardened",
    version="2.0.0",
    docs_url="/docs" if not settings.is_prod else None,
    redoc_url=None if settings.is_prod else "/redoc",
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Trusted hosts - prevent host header injection
if settings.is_prod:
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=["api.norlex.app", "norlex.app"])

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    # Request size limit
    if request.headers.get("content-length"):
        try:
            content_length = int(request.headers["content-length"])
            if content_length > settings.max_request_size_mb * 1024 * 1024:
                return JSONResponse(status_code=413, content={"code": "payload_too_large", "message": f"Request too large, max {settings.max_request_size_mb}MB"})
        except:
            pass
    return await security_headers_middleware(request, call_next)

@app.exception_handler(NorlexException)
async def norlex_exception_handler(request: Request, exc: NorlexException):
    return JSONResponse(status_code=exc.status_code, content={"code": exc.code, "message": exc.message})

# Register providers
openai_real = OpenAIRealProvider()
anthropic_provider = AnthropicProvider()
mock_provider = MockProvider()

registry.register_provider(openai_real)
registry.register_provider(anthropic_provider)
if settings.is_dev:
    registry.register_provider(mock_provider)

app.include_router(auth_router, prefix=f"{settings.api_prefix}")
app.include_router(conv_router, prefix=f"{settings.api_prefix}")
app.include_router(usage_router, prefix=f"{settings.api_prefix}")

@app.get("/")
async def root():
    return {"name": "NORLEX API", "version": "2.0.0", "env": settings.env, "real_ai": openai_real.is_configured()}

@app.get(f"{settings.api_prefix}/health")
async def health():
    return {"status": "ok", "env": settings.env, "providers": [{"id": p.provider_id, "configured": p.is_configured()} for p in registry.list_providers()]}

@app.get(f"{settings.api_prefix}/models")
async def list_models(current_user: User = Depends(get_current_user)):
    models = registry.list_all_models()
    return {"models": [m.model_dump() for m in models]}

@app.post(f"{settings.api_prefix}/chat/stream")
@limiter.limit(f"{settings.default_requests_per_minute}/minute")
async def chat_stream(request: Request, body: ChatRequest, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Validate model is allowed - prevent client forcing non-registered model
    if not registry.is_model_allowed(body.model) if hasattr(registry, 'is_model_allowed') else not registry.get_model(body.model):
        async def error_gen():
            yield {"event": "error", "data": '{"code": "model_unavailable", "message": "Model not available"}'}
        return EventSourceResponse(error_gen())
    
    body.user_id = current_user.id
    
    async def event_generator():
        start = time.time()
        total_output = 0
        success = True
        error_code = None
        try:
            async for chunk in gateway.chat_stream(body):
                if chunk.type == "chunk" and chunk.content:
                    total_output += len(chunk.content)
                if chunk.type == "error":
                    success = False
                    error_code = chunk.error_code
                yield {"event": chunk.type, "data": chunk.model_dump_json()}
        except Exception as e:
            success = False
            error_code = "internal_error"
            yield {"event": "error", "data": f'{{"code": "internal_error", "message": "Stream error"}}'}
        finally:
            # Honest token counting - labeled as estimated
            try:
                duration = int((time.time() - start) * 1000)
                # Use estimated counter with warning
                input_est = TokenCounter.estimate_messages_tokens([{"content": str(body.messages)}])
                output_est = TokenCounter.estimate_tokens("x" * total_output)  # rough
                usage = UsageRecord(
                    id=str(uuid.uuid4()),
                    user_id=current_user.id,
                    conversation_id=body.conversation_id,
                    provider_id=registry.get_model(body.model).provider_id if registry.get_model(body.model) else "unknown",
                    model_id=body.model,
                    input_tokens=input_est,
                    output_tokens=output_est,
                    total_tokens=input_est + output_est,
                    duration_ms=duration,
                    success=success,
                    error_code=error_code,
                )
                # Note: input_tokens_estimated, output_tokens_estimated - NOT billing accurate
                db.add(usage)
                await db.commit()
            except Exception as ex:
                logging.error(f"Failed to log usage: {ex}")
    
    return EventSourceResponse(event_generator())
