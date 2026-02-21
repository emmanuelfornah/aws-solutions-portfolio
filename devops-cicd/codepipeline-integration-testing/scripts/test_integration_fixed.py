"""
Integration Tests for Flask Application (Fixed Version)
This file contains the corrected integration tests with proper assertions.
"""

import pytest
from app import app


@pytest.fixture
def client():
    """
    Create a test client for the Flask application.
    This fixture sets up the app in testing mode and provides a client
    for making HTTP requests during tests.
    """
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_home_page(client):
    """
    Test that the home page loads successfully.
    Verifies the HTTP status code and presence of expected content.
    """
    response = client.get('/')
    assert response.status_code == 200
    assert b'Welcome' in response.data


def test_about_page(client):
    """
    Test that the about page loads successfully.
    """
    response = client.get('/about')
    assert response.status_code == 200
    assert b'About' in response.data


def test_api_endpoint(client):
    """
    Test API endpoint returns correct data.
    FIXED: Now expects 'success' status (correct value).
    """
    response = client.get('/api/data')
    assert response.status_code == 200
    assert response.json['status'] == 'success'  # Fixed assertion


def test_api_health_check(client):
    """
    Test health check endpoint returns healthy status.
    """
    response = client.get('/api/health')
    assert response.status_code == 200
    assert response.json['status'] == 'healthy'


def test_404_error(client):
    """
    Test that non-existent routes return 404.
    """
    response = client.get('/nonexistent')
    assert response.status_code == 404


def test_post_request(client):
    """
    Test POST request to API endpoint.
    """
    data = {'name': 'test', 'value': 123}
    response = client.post('/api/data', json=data)
    assert response.status_code == 201
    assert 'id' in response.json


def test_content_type_headers(client):
    """
    Test that API endpoints return correct content type.
    """
    response = client.get('/api/data')
    assert response.content_type == 'application/json'


def test_multiple_requests(client):
    """
    Test that multiple requests work correctly.
    Verifies the application can handle sequential requests.
    """
    for i in range(5):
        response = client.get('/')
        assert response.status_code == 200
