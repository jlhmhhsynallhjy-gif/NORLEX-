
"""
Token counting - honest estimation vs real counting
DO NOT use len//4 as billing-accurate. Must be labeled estimated.
"""

from typing import List
import math

class TokenCounter:
    """
    Honest token counting.
    - estimate_tokens: fast, rough, NOT billing accurate
    - For real billing, need tiktoken for OpenAI, anthropic tokenizer for Claude
    - All usage records store estimated_tokens with flag is_estimated=True
    """
    
    @staticmethod
    def estimate_tokens(text: str) -> int:
        """
        Very rough estimation: ~4 chars per token for English, ~2 for Arabic
        NOT accurate for billing. Labeled as estimated.
        """
        if not text:
            return 0
        # Simple heuristic: average 4 chars per token, but Arabic is ~2-3
        # This is NOT accurate - must be replaced with tiktoken in production
        return max(1, len(text) // 4)
    
    @staticmethod
    def estimate_messages_tokens(messages: List[dict]) -> int:
        total = 0
        for m in messages:
            content = m.get("content", "") if isinstance(m, dict) else getattr(m, "content", "")
            total += TokenCounter.estimate_tokens(str(content))
            total += 4  # overhead per message
        total += 3  # priming
        return total
    
    @staticmethod
    def is_estimated_warning() -> str:
        return "Token counts are ESTIMATED (len//4 heuristic), NOT billing-accurate. Real counting requires tiktoken/anthropic tokenizer."

# Usage in code should always store:
# input_tokens_estimated, output_tokens_estimated, is_estimated=True
