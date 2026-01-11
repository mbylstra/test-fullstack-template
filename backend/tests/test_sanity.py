"""Basic sanity check tests for the Fllstck Tmplt API."""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_root_endpoint():
    """Test that the root endpoint returns a healthy status."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "message" in data


def test_health_check_endpoint():
    """Test that the health check endpoint returns ok status."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"


def test_app_metadata():
    """Test that the app has correct metadata."""
    assert app.title == "Fllstck Tmplt API"
    assert app.version == "0.1.0"
