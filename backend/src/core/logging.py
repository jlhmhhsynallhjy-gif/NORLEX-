import logging
import uuid
from contextvars import ContextVar
import json
from datetime import datetime

request_id_ctx: ContextVar[str] = ContextVar("request_id", default="")
correlation_id_ctx: ContextVar[str] = ContextVar("correlation_id", default="")

class StructuredLogger:
    def __init__(self, name: str):
        self.logger = logging.getLogger(name)
    
    def _base_fields(self):
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "request_id": request_id_ctx.get(),
            "correlation_id": correlation_id_ctx.get(),
        }
    
    def info(self, msg: str, **kwargs):
        # NEVER log secrets, tokens, api keys, or full conversation content
        safe_kwargs = self._sanitize(kwargs)
        self.logger.info(json.dumps({**self._base_fields(), "level": "info", "message": msg, **safe_kwargs}))
    
    def error(self, msg: str, **kwargs):
        safe_kwargs = self._sanitize(kwargs)
        self.logger.error(json.dumps({**self._base_fields(), "level": "error", "message": msg, **safe_kwargs}))
    
    def warning(self, msg: str, **kwargs):
        safe_kwargs = self._sanitize(kwargs)
        self.logger.warning(json.dumps({**self._base_fields(), "level": "warning", "message": msg, **safe_kwargs}))
    
    def _sanitize(self, data: dict) -> dict:
        # Remove sensitive fields
        sensitive = {"api_key", "token", "authorization", "password", "secret", "openai_api_key", "anthropic_api_key"}
        return {k: ("***REDACTED***" if k.lower() in sensitive else v) for k, v in data.items()}

def get_logger(name: str) -> StructuredLogger:
    return StructuredLogger(name)
