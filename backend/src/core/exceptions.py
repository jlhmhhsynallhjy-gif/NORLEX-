from fastapi import HTTPException, status

class NorlexException(HTTPException):
    def __init__(self, status_code: int, code: str, message: str, details=None):
        super().__init__(status_code=status_code, detail={"code": code, "message": message, "details": details})
        self.code = code
        self.message = message

class ProviderNotConfigured(NorlexException):
    def __init__(self, provider: str):
        super().__init__(status_code=503, code="provider_unavailable", message=f"AI provider {provider} not configured", details={"provider": provider})

class RateLimitExceeded(NorlexException):
    def __init__(self, limit: int):
        super().__init__(status_code=429, code="rate_limited", message=f"Rate limit exceeded: {limit} requests/minute")

class TokenLimitExceeded(NorlexException):
    def __init__(self, limit: int):
        super().__init__(status_code=429, code="token_limit_exceeded", message=f"Daily token limit exceeded: {limit}")

class UnauthorizedException(NorlexException):
    def __init__(self, message="Unauthorized"):
        super().__init__(status_code=401, code="unauthorized", message=message)

class InvalidRequestException(NorlexException):
    def __init__(self, message, code="invalid_request"):
        super().__init__(status_code=400, code=code, message=message)
