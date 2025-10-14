"""Tests for main module."""

import pytest

from myproject.main import Settings


def test_settings_defaults():
    """Test that settings have correct defaults."""
    settings = Settings()
    assert settings.log_level == "INFO"


def test_settings_with_env(monkeypatch):
    """Test that settings can be loaded from environment."""
    monkeypatch.setenv("LOG_LEVEL", "DEBUG")
    monkeypatch.setenv("ANTHROPIC_API_KEY", "test-key")

    settings = Settings()
    assert settings.log_level == "DEBUG"
    assert settings.anthropic_api_key == "test-key"
