from typing import AsyncGenerator, Optional
from ..providers.base import ChatRequest, ChatChunk
from .model_registry import registry
from ...core.exceptions import ProviderNotConfigured, InvalidRequestException
from ...core.logging import get_logger

logger = get_logger("ai_gateway")

class AIGateway:
    def __init__(self):
        self.registry = registry
    
    async def chat_completion(self, request: ChatRequest) -> str:
        model_info = self.registry.get_model(request.model)
        if not model_info:
            raise InvalidRequestException(f"Model {request.model} not found or unavailable", code="model_unavailable")
        
        provider = self.registry.get_provider(model_info.provider_id)
        if not provider or not provider.is_configured():
            raise ProviderNotConfigured(model_info.provider_id)
        
        logger.info("chat_completion", model=request.model, provider=model_info.provider_id, user_id=request.user_id)
        
        return await provider.chat_completion(request)
    
    async def chat_stream(self, request: ChatRequest) -> AsyncGenerator[ChatChunk, None]:
        model_info = self.registry.get_model(request.model)
        if not model_info:
            yield ChatChunk(type="error", error_code="model_unavailable", error_message=f"Model {request.model} not available")
            return
        
        provider = self.registry.get_provider(model_info.provider_id)
        if not provider or not provider.is_configured():
            yield ChatChunk(type="error", error_code="provider_unavailable", error_message=f"Provider {model_info.provider_id} not configured")
            return
        
        logger.info("chat_stream_start", model=request.model, provider=model_info.provider_id, conversation_id=request.conversation_id)
        
        try:
            async for chunk in provider.chat_stream(request):
                yield chunk
        except Exception as e:
            logger.error("chat_stream_error", error=str(e), model=request.model)
            yield ChatChunk(type="error", error_code="provider_error", error_message="Provider error occurred")

gateway = AIGateway()
