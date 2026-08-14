from fastapi import Request, Response
from fastapi.responses import JSONResponse
import time
import uuid
from ..core.logging import request_id_ctx, correlation_id_ctx, get_logger

logger = get_logger("security_middleware")

async def security_headers_middleware(request: Request, call_next):
    # Request ID for observability
    req_id = str(uuid.uuid4())
    request_id_ctx.set(req_id)
    correlation_id_ctx.set(request.headers.get("X-Correlation-ID", req_id))
    
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start
    
    # Secure headers
    response.headers["X-Request-ID"] = req_id
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    
    logger.info("request_completed", method=request.method, path=request.url.path, status=response.status_code, duration_ms=int(duration*1000))
    
    return response
