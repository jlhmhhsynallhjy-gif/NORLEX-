from typing import List, Dict, Optional
from ..providers.base import AIProviderAdapter
from ..models.capabilities import ModelInfo

class ModelRegistry:
    def __init__(self):
        self._providers: Dict[str, AIProviderAdapter] = {}
        self._models: Dict[str, ModelInfo] = {}
    
    def register_provider(self, provider: AIProviderAdapter):
        self._providers[provider.provider_id] = provider
        # Register its models
        for model in provider.list_models():
            key = f"{provider.provider_id}/{model.model_id}"
            self._models[key] = model
            self._models[model.model_id] = model  # also by model_id alone
    
    def get_provider(self, provider_id: str) -> Optional[AIProviderAdapter]:
        return self._providers.get(provider_id)
    
    def get_model(self, model_id: str) -> Optional[ModelInfo]:
        return self._models.get(model_id)
    
    def list_all_models(self) -> List[ModelInfo]:
        models = []
        for provider in self._providers.values():
            models.extend(provider.list_models())
        return [m for m in models if m.is_available]
    
    def list_providers(self) -> List[AIProviderAdapter]:
        return list(self._providers.values())
    
    def get_available_models(self) -> List[ModelInfo]:
        return [m for m in self._models.values() if m.is_available and "/" not in m.model_id]  # dedup

# Global registry
registry = ModelRegistry()
