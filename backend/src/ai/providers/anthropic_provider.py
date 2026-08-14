from typing import List, Optional, AsyncGenerator
from .base import AIProviderAdapter, ChatRequest, ChatChunk
from ..models.capabilities import ModelInfo, ProviderCapability
from ...config.settings import settings

class AnthropicProvider(AIProviderAdapter):
    provider_id = "anthropic"
    display_name = "Anthropic"
    
    def __init__(self):
        self.api_key = settings.anthropic_api_key
        self._models = [
            ModelInfo(
                provider_id=self.provider_id,
                model_id="claude-3-5-sonnet-20241022",
                display_name="Claude 3.5 Sonnet",
                context_window=200000,
                capabilities={ProviderCapability.CHAT, ProviderCapability.STREAMING, ProviderCapability.VISION, ProviderCapability.TOOLS},
                supports_streaming=True, supports_vision=True, supports_tools=True, is_available=self.is_configured()
            ),
        ]
    
    def is_configured(self) -> bool:
        return bool(self.api_key and self.api_key.strip() not in ("", "test"))
    
    def list_models(self) -> List[ModelInfo]:
        return self._models if self.is_configured() else []
    
    def get_model(self, model_id: str) -> Optional[ModelInfo]:
        for m in self._models:
            if m.model_id == model_id and self.is_configured():
                return m
        return None
    
    async def chat_completion(self, request: ChatRequest) -> str:
        if not self.is_configured():
            raise Exception("Anthropic not configured")
        raise NotImplementedError("Anthropic completion requires real key")
    
    async def chat_stream(self, request: ChatRequest) -> AsyncGenerator[ChatChunk, None]:
        if not self.is_configured():
            yield ChatChunk(type="error", error_code="provider_unavailable", error_message="Anthropic not configured")
            return
        yield ChatChunk(type="start")
        yield ChatChunk(type="error", error_code="not_implemented", error_message="Anthropic streaming foundation only")
