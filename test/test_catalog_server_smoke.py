import asyncio
import os
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

from fastapi import HTTPException

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

# Ensure dummy key for import in test environments
os.environ.setdefault("GEMINI_API_KEY", "dummy_key_for_testing")

from catalog_server import (
    VoiceAssistantRequest,
    VoicePayload,
    app,
    catalog_model,
    generate_catalog,
    health,
    voice_assistant,
)


def test_health_endpoint():
    result = health()
    assert result == {"status": "ok", "service": "catalog"}


def test_generate_catalog_endpoint_registered():
    routes = [getattr(route, "path", None) for route in app.routes]
    assert "/api/generate-catalog" in routes
    assert "/api/voice-assistant" in routes
    assert "/health" in routes


def test_voice_assistant_rejects_empty():
    try:
        asyncio.run(voice_assistant(VoiceAssistantRequest(question="")))
        assert False, "Should have raised HTTPException"
    except HTTPException as exc:
        assert exc.status_code == 400
        assert "cannot be empty" in exc.detail


def test_voice_assistant_rejects_whitespace_only():
    try:
        asyncio.run(voice_assistant(VoiceAssistantRequest(question="   \n\t ")))
        assert False, "Should have raised HTTPException"
    except HTTPException as exc:
        assert exc.status_code == 400
        assert "cannot be empty" in exc.detail


def test_voice_assistant_rejects_empty_transcript_field():
    try:
        asyncio.run(voice_assistant(VoiceAssistantRequest(transcript="   ")))
        assert False, "Should have raised HTTPException"
    except HTTPException as exc:
        assert exc.status_code == 400
        assert "cannot be empty" in exc.detail


def test_voice_assistant_provider_failure_does_not_expose_raw_exception():
    with patch.object(
        catalog_model,
        "generate_content",
        side_effect=RuntimeError("Raw internal Gemini connection failed"),
    ):
        try:
            asyncio.run(
                voice_assistant(
                    VoiceAssistantRequest(question="How do I add a product?")
                )
            )
            assert False, "Should have raised HTTPException"
        except HTTPException as exc:
            assert exc.status_code == 500
            assert "Raw internal Gemini" not in exc.detail
            assert "Failed to generate response" in exc.detail


def test_voice_assistant_valid_mocked_response_returns_structured_answer():
    mock_response = MagicMock()
    mock_response.text = (
        "To add a product, tap the Add Product button and enter your product details."
    )
    with patch.object(catalog_model, "generate_content", return_value=mock_response):
        result = asyncio.run(
            voice_assistant(
                VoiceAssistantRequest(question="How do I add a product?")
            )
        )
        assert result.get("status") == "success"
        assert (
            result.get("answer")
            == "To add a product, tap the Add Product button and enter your product details."
        )


def test_voice_assistant_also_accepts_transcript_field():
    mock_response = MagicMock()
    mock_response.text = "Artisans selling intra-state under 40 Lakhs are exempt."
    with patch.object(catalog_model, "generate_content", return_value=mock_response):
        result = asyncio.run(
            voice_assistant(VoiceAssistantRequest(transcript="Do I need GST?"))
        )
        assert result.get("status") == "success"
        assert "under 40 Lakhs" in result.get("answer", "")


if __name__ == "__main__":
    test_health_endpoint()
    test_generate_catalog_endpoint_registered()
    test_voice_assistant_rejects_empty()
    test_voice_assistant_rejects_whitespace_only()
    test_voice_assistant_rejects_empty_transcript_field()
    test_voice_assistant_provider_failure_does_not_expose_raw_exception()
    test_voice_assistant_valid_mocked_response_returns_structured_answer()
    test_voice_assistant_also_accepts_transcript_field()
    print("ALL 8 BACKEND TESTS PASSED!")
