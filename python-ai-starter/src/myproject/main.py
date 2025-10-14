"""Main application module."""

import structlog
from pydantic_settings import BaseSettings, SettingsConfigDict


logger = structlog.get_logger()


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # API Keys
    anthropic_api_key: str | None = None
    openai_api_key: str | None = None
    huggingface_token: str | None = None

    # Application Settings
    log_level: str = "INFO"


def main() -> None:
    """Main entry point."""
    settings = Settings()

    structlog.configure(
        wrapper_class=structlog.make_filtering_bound_logger(
            getattr(structlog.stdlib, settings.log_level.upper(), structlog.stdlib.INFO)
        ),
    )

    logger.info("Application started", version="0.1.0")

    # Your application logic here


if __name__ == "__main__":
    main()
