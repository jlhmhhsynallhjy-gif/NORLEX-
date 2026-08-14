from enum import Enum
from typing import Set
from pydantic import BaseModel

class ProviderCapability(str, Enum):
    CHAT = "chat"
    STREAMING = "streaming"
    VISION = "vision"
    TOOLS = "tools"
    STRUCTURED_OUTPUT = "structured_output"
    AUDIO = "audio"
    EMBEDDINGS = "embeddings"
    TRANSCRIPTION = "transcription"

class ModelInfo(BaseModel):
    provider_id: str
    model_id: str
    display_name: str
    context_window: int
    capabilities: Set[ProviderCapability]
    max_output_tokens: int = 4096
    supports_streaming: bool = True
    supports_vision: bool = False
    supports_tools: bool = False
    is_available: bool = True
    pricing_input_per_1k: float = 0.0
    pricing_output_per_1k: float = 0.0
    
    @property
    def is_chat_available(self) -> bool:
        return ProviderCapability.CHAT in self.capabilities and self.is_available
