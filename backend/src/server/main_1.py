
from fastapi import FastAPI, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from sse_starlette.sse import EventSourceResponse
from typing import List
import logging
import time
import uuid

from ..config.settings import settings
from ..ai.providers.openai_real import OpenAIRealProvider
from ..ai.providers.anthropic_provider import AnthropicProvider
from ..ai.providers.mock_provider import MockProvider
from ..ai.gateway.model_registry import registry
from ..ai.gateway.gateway import gateway
from ..ai.providers.base import ChatRequest, ChatMessage
from ..middleware.security import security_headers_middleware
from ..core.exceptions import NorlexException
from ..core.database import get_db, init_db
from ..models.user import User
from ..auth.dependencies import get_current_user
from ..auth.router import router as auth_router
from ..conversations.router import router as conv_router
from ..usage.router import router as usage_router
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from ..models.usage import UsageRecord

# Setup
limiter = Limiter(key_func=get_remote_address, default_limits=[f"{settings.rate_limit_per_minute}/minute"])
app = FastAPI(
    title="NORLEX API",
    description="NORLEX Unified AI Platform - Backend Gateway with Real AI",
    version="2.0.0",
    docs_url="/docs" if not settings.is_prod else None,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

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

@app.exception_handler(NorlexException)
async def norlex_exception_handler(request: Request, exc: NorlexException):
    return JSONResponse(status_code=exc.status_code, content={"code": exc.code, "message": exc.message})

# Register providers - REAL
openai_real = OpenAIRealProvider()
anthropic_provider = AnthropicProvider()
mock_provider = MockProvider()

registry.register_provider(openai_real)
registry.register_provider(anthropic_provider)
if settings.is_dev:
    registry.register_provider(mock_provider)

# Include routers
app.include_router(auth_router, prefix=f"{settings.api_prefix}")
app.include_router(conv_router, prefix=f"{settings.api_prefix}")
app.include_router(usage_router, prefix=f"{settings.api_prefix}")

@app.on_event("startup")
async def startup():
    if "sqlite" in settings.database_url:
        await init_db()
        logging.info("Database initialized (dev)")

@app.get("/")
async def root():
    return {"name": "NORLEX API", "version": "2.0.0", "env": settings.env, "real_ai": openai_real.is_configured()}

@app.get(f"{settings.api_prefix}/health")
async def health():
    return {"status": "ok", "env": settings.env, "providers": [{"id": p.provider_id, "configured": p.is_configured(), "models": len(p.list_models())} for p in registry.list_providers()]}

@app.get(f"{settings.api_prefix}/models")
async def list_models(current_user: User = Depends(get_current_user)):
    models = registry.list_all_models()
    return {"models": [m.model_dump() for m in models]}

@app.get(f"{settings.api_prefix}/models/public")
async def list_models_public():
    # Public endpoint for model discovery before auth? Only returns available status, no secrets
    models = registry.list_all_models()
    return {"models": [{"provider_id": m.provider_id, "model_id": m.model_id, "display_name": m.display_name, "is_available": m.is_available} for m in models]}

@app.post(f"{settings.api_prefix}/chat/completions")
@limiter.limit(f"{settings.default_requests_per_minute}/minute")
async def chat_completions(
    request: Request,
    body: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    from ..ai.policies.cost_protection import cost_protection
    if not cost_protection.check_and_record(current_user.id, body.max_tokens or 100):
        raise NorlexException(429, "rate_limited", "Rate or token limit exceeded")
    
    try:
        start = time.time()
        response = await gateway.chat_completion(body)
        duration = int((time.time() - start) * 1000)
        
        # Usage tracking - no content logged
        usage = UsageRecord(
            id=str(uuid.uuid4()),
            user_id=current_user.id,
            conversation_id=body.conversation_id,
            provider_id=registry.get_model(body.model).provider_id if registry.get_model(body.model) else "unknown",
            model_id=body.model,
            input_tokens=len(str(body.messages)) // 4,  # rough estimate, real would use tiktoken
            output_tokens=len(response) // 4,
            total_tokens=(len(str(body.messages)) + len(response)) // 4,
            duration_ms=duration,
            success=True,
        )
        db.add(usage)
        await db.commit()
        
        return {"content": response, "model": body.model}
    except NorlexException:
        raise
    except Exception as e:
        logging.error(f"chat_completions error: {e}")
        # Log failed usage
        try:
            usage = UsageRecord(
                id=str(uuid.uuid4()),
                user_id=current_user.id,
                provider_id="unknown",
                model_id=body.model,
                success=False,
                error_code="provider_error",
                duration_ms=int((time.time() - start) * 1000) if 'start' in locals() else 0,
            )
            db.add(usage)
            await db.commit()
        except:
            pass
        raise NorlexException(500, "internal_error", "Internal server error")

@app.post(f"{settings.api_prefix}/chat/stream")
@limiter.limit(f"{settings.default_requests_per_minute}/minute")
async def chat_stream(
    request: Request,
    body: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    from ..ai.policies.cost_protection import cost_protection
    if not cost_protection.check_and_record(current_user.id, body.max_tokens or 100):
        async def error_gen():
            yield {"event": "error", "data": '{"code": "rate_limited", "message": "Rate limit exceeded"}'}
        return EventSourceResponse(error_gen())
    
    # Override user_id from auth
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
            yield {"event": "error", "data": f'{{"code": "internal_error", "message": "Stream error: {str(e)}"}}'}
        finally:
            # Usage tracking - no content
            try:
                duration = int((time.time() - start) * 1000)
                usage = UsageRecord(
                    id=str(uuid.uuid4()),
                    user_id=current_user.id,
                    conversation_id=body.conversation_id,
                    provider_id=registry.get_model(body.model).provider_id if registry.get_model(body.model) else "unknown",
                    model_id=body.model,
                    input_tokens=len(str(body.messages)) // 4,
                    output_tokens=total_output // 4,
                    total_tokens=(len(str(body.messages)) // 4 + total_output // 4),
                    duration_ms=duration,
                    success=success,
                    error_code=error_code,
                )
                async with db as session:
                    session.add(usage)
                    await session.commit()
            except Exception as ex:
                logging.error(f"Failed to log usage: {ex}")
    
    return EventSourceResponse(event_generator())
