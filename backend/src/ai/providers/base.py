from abc import ABC, abstractmethod
from typing import AsyncGenerator, List, Optional
from ..models.capabilities import ModelInfo, ProviderCapability
from pydantic import BaseModel

class ChatMessage(BaseModel):
    role: str  # user, assistant, system, tool
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    model: str
    stream: bool = False
    max_tokens: Optional[int] = None
    temperature: float = 0.7
    user_id: Optional[str] = None
    conversation_id: Optional[str] = None

class ChatChunk(BaseModel):
    type: str  # start, chunk, tool_event, completed, error
    content: Optional[str] = None
    tool_name: Optional[str] = None
    tool_status: Optional[str] = None
    finish_reason: Optional[str] = None
    usage: Optional[dict] = None
    error_code: Optional[str] = None
    error_message: Optional[str] = None

class AIProviderAdapter(ABC):
    provider_id: str
    display_name: str
    
    @abstractmethod
    def is_configured(self) -> bool:
        pass
    
    @abstractmethod
    def list_models(self) -> List[ModelInfo]:
        pass
    
    @abstractmethod
    def get_model(self, model_id: str) -> Optional[ModelInfo]:
        pass
    
    @abstractmethod
    async def chat_completion(self, request: ChatRequest) -> str:
        pass
    
    @abstractmethod
    def chat_stream(self, request: ChatRequest) -> AsyncGenerator[ChatChunk, None]:
        pass
    
    def supports_capability(self, capability: ProviderCapability) -> bool:
        return any(capability in m.capabilities for m in self.list_models())
