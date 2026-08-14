from typing import List, Optional, AsyncGenerator
import httpx
from .base import AIProviderAdapter, ChatRequest, ChatChunk
from ..models.capabilities import ModelInfo, ProviderCapability
from ...config.settings import settings
from ...core.logging import get_logger

logger = get_logger("openai_provider")

class OpenAIProvider(AIProviderAdapter):
    provider_id = "openai"
    display_name = "OpenAI"
    
    def __init__(self):
        self.api_key = settings.openai_api_key
        self.base_url = settings.openai_base_url or "https://api.openai.com/v1"
        self._models = [
            ModelInfo(
                provider_id=self.provider_id,
                model_id="gpt-4o",
                display_name="GPT-4o",
                context_window=128000,
                capabilities={ProviderCapability.CHAT, ProviderCapability.STREAMING, ProviderCapability.VISION, ProviderCapability.TOOLS, ProviderCapability.STRUCTURED_OUTPUT},
                supports_streaming=True, supports_vision=True, supports_tools=True, is_available=self.is_configured(),
                pricing_input_per_1k=0.005, pricing_output_per_1k=0.015
            ),
            ModelInfo(
                provider_id=self.provider_id,
                model_id="gpt-4o-mini",
                display_name="GPT-4o Mini",
                context_window=128000,
                capabilities={ProviderCapability.CHAT, ProviderCapability.STREAMING, ProviderCapability.VISION, ProviderCapability.TOOLS},
                supports_streaming=True, supports_vision=True, supports_tools=True, is_available=self.is_configured(),
                pricing_input_per_1k=0.00015, pricing_output_per_1k=0.0006
            ),
        ]
    
    def is_configured(self) -> bool:
        return bool(self.api_key and self.api_key.strip() not in ("", "test", "placeholder"))
    
    def list_models(self) -> List[ModelInfo]:
        return self._models if self.is_configured() else []
    
    def get_model(self, model_id: str) -> Optional[ModelInfo]:
        for m in self._models:
            if m.model_id == model_id:
                return m if self.is_configured() else None
        return None
    
    async def chat_completion(self, request: ChatRequest) -> str:
        if not self.is_configured():
            raise Exception("OpenAI provider not configured - API key missing")
        # Real implementation would call OpenAI API via httpx/openai SDK
        # For foundation, we keep structure but don't fake response
        async with httpx.AsyncClient(timeout=settings.provider_timeout) as client:
            # Placeholder for real call - actual call requires real key
            raise NotImplementedError("Real OpenAI call requires configured key and will be implemented with openai SDK")
    
    async def chat_stream(self, request: ChatRequest) -> AsyncGenerator[ChatChunk, None]:
        if not self.is_configured():
            yield ChatChunk(type="error", error_code="provider_unavailable", error_message="OpenAI not configured")
            return
        
        # SSE streaming structure - real implementation:
        # yield start, then chunks, then completed
        # This is foundation - real streaming will use openai.AsyncOpenAI().chat.completions.create(stream=True)
        yield ChatChunk(type="start", content=None)
        # Real chunks would come from provider
        # For now, yield error to keep honest - no fake responses
        yield ChatChunk(type="error", error_code="not_implemented", error_message="Streaming not yet connected - backend foundation only")
