
from typing import List, Optional, AsyncGenerator
import time
from .base import AIProviderAdapter, ChatRequest, ChatChunk
from ..models.capabilities import ModelInfo, ProviderCapability
from ...config.settings import settings
from ...core.logging import get_logger

logger = get_logger("openai_real")

class OpenAIRealProvider(AIProviderAdapter):
    provider_id = "openai"
    display_name = "OpenAI"
    
    def __init__(self):
        self.api_key = settings.openai_api_key
        self.base_url = settings.openai_base_url or "https://api.openai.com/v1"
        self._models = [
            ModelInfo(
                provider_id=self.provider_id,
                model_id="gpt-4o-mini",
                display_name="GPT-4o Mini (Real)",
                context_window=128000,
                capabilities={ProviderCapability.CHAT, ProviderCapability.STREAMING, ProviderCapability.VISION, ProviderCapability.TOOLS},
                supports_streaming=True, supports_vision=True, supports_tools=True,
                is_available=self.is_configured(),
                pricing_input_per_1k=0.00015, pricing_output_per_1k=0.0006
            ),
            ModelInfo(
                provider_id=self.provider_id,
                model_id="gpt-4o",
                display_name="GPT-4o (Real)",
                context_window=128000,
                capabilities={ProviderCapability.CHAT, ProviderCapability.STREAMING, ProviderCapability.VISION, ProviderCapability.TOOLS, ProviderCapability.STRUCTURED_OUTPUT},
                supports_streaming=True, supports_vision=True, supports_tools=True,
                is_available=self.is_configured(),
                pricing_input_per_1k=0.005, pricing_output_per_1k=0.015
            ),
        ]
        self._client = None
    
    def _get_client(self):
        if self._client is None and self.is_configured():
            try:
                from openai import AsyncOpenAI
                self._client = AsyncOpenAI(api_key=self.api_key, base_url=self.base_url if self.base_url != "https://api.openai.com/v1" else None)
            except Exception as e:
                logger.error("openai_client_init_failed", error=str(e))
        return self._client
    
    def is_configured(self) -> bool:
        # Real check - API key must be present and not placeholder
        return bool(self.api_key and len(self.api_key.strip()) > 20 and self.api_key.startswith("sk-"))
    
    def list_models(self) -> List[ModelInfo]:
        if not self.is_configured():
            return []
        return self._models
    
    def get_model(self, model_id: str) -> Optional[ModelInfo]:
        for m in self._models:
            if m.model_id == model_id and self.is_configured():
                return m
        return None
    
    async def chat_completion(self, request: ChatRequest) -> str:
        if not self.is_configured():
            raise Exception("OpenAI provider not configured - API key missing or invalid")
        
        client = self._get_client()
        if not client:
            raise Exception("Failed to create OpenAI client")
        
        try:
            messages = [{"role": m.role, "content": m.content} for m in request.messages]
            response = await client.chat.completions.create(
                model=request.model,
                messages=messages,
                max_tokens=request.max_tokens,
                temperature=request.temperature,
            )
            return response.choices[0].message.content or ""
        except Exception as e:
            logger.error("openai_completion_error", error=str(e), model=request.model)
            raise
    
    async def chat_stream(self, request: ChatRequest) -> AsyncGenerator[ChatChunk, None]:
        if not self.is_configured():
            yield ChatChunk(type="error", error_code="provider_unavailable", error_message="OpenAI API key not configured in backend")
            return
        
        client = self._get_client()
        if not client:
            yield ChatChunk(type="error", error_code="provider_error", error_message="Failed to create OpenAI client")
            return
        
        try:
            messages = [{"role": m.role, "content": m.content} for m in request.messages]
            yield ChatChunk(type="start", content=None)
            
            stream = await client.chat.completions.create(
                model=request.model,
                messages=messages,
                max_tokens=request.max_tokens,
                temperature=request.temperature,
                stream=True,
            )
            
            async for chunk in stream:
                if chunk.choices and len(chunk.choices) > 0:
                    delta = chunk.choices[0].delta
                    if delta.content:
                        yield ChatChunk(type="chunk", content=delta.content)
                    if chunk.choices[0].finish_reason:
                        yield ChatChunk(type="completed", finish_reason=chunk.choices[0].finish_reason, usage={"model": request.model})
            
        except Exception as e:
            logger.error("openai_stream_error", error=str(e), model=request.model)
            yield ChatChunk(type="error", error_code="provider_error", error_message=str(e))
