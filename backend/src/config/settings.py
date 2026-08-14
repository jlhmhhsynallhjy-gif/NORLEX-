from pydantic_settings import BaseSettings
from pydantic import Field
from typing import List, Optional
import os

class Settings(BaseSettings):
    env: str = Field(default="development", alias="ENV")
    host: str = Field(default="0.0.0.0", alias="HOST")
    port: int = Field(default=8000, alias="PORT")
    api_prefix: str = Field(default="/api/v1", alias="API_PREFIX")
    
    database_url: str = Field(default="sqlite:///./norlex.db", alias="DATABASE_URL")
    
    jwt_secret: str = Field(default="dev-secret-change-in-prod-min-32-chars", alias="JWT_SECRET")
    jwt_access_expire_minutes: int = Field(default=15, alias="JWT_ACCESS_TOKEN_EXPIRE_MINUTES")
    jwt_refresh_expire_days: int = Field(default=7, alias="JWT_REFRESH_TOKEN_EXPIRE_DAYS")
    jwt_algorithm: str = Field(default="HS256", alias="JWT_ALGORITHM")
    
    openai_api_key: Optional[str] = Field(default=None, alias="OPENAI_API_KEY")
    anthropic_api_key: Optional[str] = Field(default=None, alias="ANTHROPIC_API_KEY")
    google_ai_api_key: Optional[str] = Field(default=None, alias="GOOGLE_AI_API_KEY")
    openai_base_url: Optional[str] = Field(default=None, alias="OPENAI_BASE_URL")
    
    cors_origins: str = Field(default="http://localhost:3000,http://localhost:8080", alias="CORS_ORIGINS")
    rate_limit_per_minute: int = Field(default=60, alias="RATE_LIMIT_PER_MINUTE")
    max_request_size_mb: int = Field(default=10, alias="MAX_REQUEST_SIZE_MB")
    
    log_level: str = Field(default="info", alias="LOG_LEVEL")
    
    default_user_daily_token_limit: int = Field(default=100000, alias="DEFAULT_USER_DAILY_TOKEN_LIMIT")
    default_requests_per_minute: int = Field(default=20, alias="DEFAULT_USER_REQUESTS_PER_MINUTE")
    default_max_tokens_per_request: int = Field(default=4096, alias="DEFAULT_MAX_TOKENS_PER_REQUEST")
    provider_timeout: int = Field(default=60, alias="PROVIDER_TIMEOUT_SECONDS")
    provider_max_retries: int = Field(default=2, alias="PROVIDER_MAX_RETRIES")
    
    enable_failover: bool = Field(default=False, alias="ENABLE_FAILOVER")
    
    @property
    def cors_origins_list(self) -> List[str]:
        return [o.strip() for o in self.cors_origins.split(",")]
    
    @property
    def is_dev(self) -> bool:
        return self.env == "development"
    
    @property
    def is_prod(self) -> bool:
        return self.env == "production"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"

settings = Settings()
