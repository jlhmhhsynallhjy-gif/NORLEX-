from typing import Dict
from datetime import datetime, timedelta
from collections import defaultdict
from ...config.settings import settings

class CostProtection:
    def __init__(self):
        self.user_daily_tokens: Dict[str, int] = defaultdict(int)
        self.user_requests_minute: Dict[str, list] = defaultdict(list)
        self.user_last_reset: Dict[str, datetime] = {}
    
    def check_and_record(self, user_id: str, estimated_tokens: int) -> bool:
        now = datetime.utcnow()
        
        # Daily reset
        last_reset = self.user_last_reset.get(user_id)
        if not last_reset or (now - last_reset).days >= 1:
            self.user_daily_tokens[user_id] = 0
            self.user_last_reset[user_id] = now
        
        # Check daily token limit
        if self.user_daily_tokens[user_id] + estimated_tokens > settings.default_user_daily_token_limit:
            return False
        
        # Check per-minute rate limit
        minute_ago = now - timedelta(minutes=1)
        self.user_requests_minute[user_id] = [t for t in self.user_requests_minute[user_id] if t > minute_ago]
        if len(self.user_requests_minute[user_id]) >= settings.default_requests_per_minute:
            return False
        
        # Record
        self.user_daily_tokens[user_id] += estimated_tokens
        self.user_requests_minute[user_id].append(now)
        return True

cost_protection = CostProtection()
