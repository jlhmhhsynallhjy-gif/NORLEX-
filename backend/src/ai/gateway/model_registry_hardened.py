
"""
Hardened Model Registry - no hardcoded availability in Flutter
"""

from typing import List, Dict, Optional
from ..providers.base import AIProviderAdapter
from ..models.capabilities import ModelInfo

class ModelRegistry:
    def __init__(self):
        self._providers: Dict[str, AIProviderAdapter] = {}
        self._models: Dict[str, ModelInfo] = {}
    
    def register_provider(self, provider: AIProviderAdapter):
        self._providers[provider.provider_id] = provider
        for model in provider.list_models():
            # Only register if provider is configured - ensures no unavailable models shown
            if model.is_available:
                key = f"{provider.provider_id}/{model.model_id}"
                self._models[key] = model
                self._models[model.model_id] = model
    
    def get_provider(self, provider_id: str) -> Optional[AIProviderAdapter]:
        return self._providers.get(provider_id)
    
    def get_model(self, model_id: str) -> Optional[ModelInfo]:
        # Validate model exists and provider configured
        model = self._models.get(model_id)
        if not model:
            return None
        provider = self._providers.get(model.provider_id)
        if not provider or not provider.is_configured():
            return None
        return model
    
    def list_all_models(self) -> List[ModelInfo]:
        # Only returns available models - critical for security
        available = []
        for provider in self._providers.values():
            if provider.is_configured():
                available.extend([m for m in provider.list_models() if m.is_available])
        # Deduplicate by model_id
        seen = set()
        deduped = []
        for m in available:
            if m.model_id not in seen:
                seen.add(m.model_id)
                deduped.append(m)
        return deduped
    
    def is_model_allowed(self, model_id: str) -> bool:
        # Prevent client forcing backend to use non-registered model
        return self.get_model(model_id) is not None

registry = ModelRegistry()
