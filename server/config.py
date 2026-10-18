from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env")

    database_url: str
    jwt_secret: str
    anthropic_api_key: str
    redis_url: str = "redis://localhost:6379/0"


settings = Settings()