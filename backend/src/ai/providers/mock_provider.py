from typing import List, Optional, AsyncGenerator
from .base import AIProviderAdapter, ChatRequest, ChatChunk
from ..models.capabilities import ModelInfo, ProviderCapability

class MockProvider(AIProviderAdapter):
    provider_id = "mock"
    display_name = "Mock (Dev Only)"
    
    def __init__(self):
        self._models = [
            ModelInfo(
                provider_id=self.provider_id,
                model_id="mock-echo",
                display_name="Mock Echo (Dev)",
                context_window=4096,
                capabilities={ProviderCapability.CHAT, ProviderCapability.STREAMING},
                supports_streaming=True, is_available=True
            ),
        ]
    
    def is_configured(self) -> bool:
        return True  # Always available for dev/testing
    
    def list_models(self) -> List[ModelInfo]:
        return self._models
    
    def get_model(self, model_id: str) -> Optional[ModelInfo]:
        for m in self._models:
            if m.model_id == model_id:
                return m
        return None
    
    async def chat_completion(self, request: ChatRequest) -> str:
        # Mock echo for testing - clearly marked as mock, not fake AI
        last_user = next((m.content for m in reversed(request.messages) if m.role == "user"), "")
        return f"[MOCK ECHO - DEV ONLY]: {last_user}"
    
    async def chat_stream(self, request: ChatRequest) -> AsyncGenerator[ChatChunk, None]:
        # Mock streaming that echoes input in chunks - for testing streaming infra only
        last_user = next((m.content for m in reversed(request.messages) if m.role == "user"), "")
        yield ChatChunk(type="start")
        # Stream echo in words
        for word in last_user.split():
            yield ChatChunk(type="chunk", content=word + " ")
        yield ChatChunk(type="completed", finish_reason="stop", usage={"input": len(last_user), "output": len(last_user)})
