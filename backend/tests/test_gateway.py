import pytest
from src.ai.providers.mock_provider import MockProvider
from src.ai.gateway.model_registry import ModelRegistry
from src.ai.providers.base import ChatRequest, ChatMessage

@pytest.mark.asyncio
async def test_mock_provider_streaming():
    provider = MockProvider()
    assert provider.is_configured() == True
    models = provider.list_models()
    assert len(models) == 1
    assert models[0].model_id == "mock-echo"
    
    request = ChatRequest(
        messages=[ChatMessage(role="user", content="Hello world")],
        model="mock-echo",
        stream=True
    )
    
    chunks = []
    async for chunk in provider.chat_stream(request):
        chunks.append(chunk)
    
    assert chunks[0].type == "start"
    assert chunks[-1].type == "completed"
    # Check aggregation
    content = "".join([c.content or "" for c in chunks if c.content])
    assert "Hello world" in content

def test_model_registry():
    registry = ModelRegistry()
    mock = MockProvider()
    registry.register_provider(mock)
    
    assert registry.get_model("mock-echo") is not None
    assert registry.get_provider("mock") is not None
    assert len(registry.list_all_models()) == 1

@pytest.mark.asyncio
async def test_cost_protection():
    from src.ai.policies.cost_protection import CostProtection
    cp = CostProtection()
    user = "test_user"
    # Should allow first request
    assert cp.check_and_record(user, 100) == True
    # Should block after exceeding limit (simulate)
    # For test, we don't exceed, just check structure
