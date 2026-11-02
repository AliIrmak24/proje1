import os
import sys
import tempfile
from pathlib import Path

import pytest

test_dir = tempfile.mkdtemp(prefix="sozegitim-test-")
os.environ["DATABASE_URL"] = f"sqlite:///{Path(test_dir) / 'test.db'}"
os.environ["SECRET_KEY"] = "test-only-secret-key-0123456789-abcdefgh"
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient

from app.core.rate_limit import login_limiter, register_limiter
from app.main import app


@pytest.fixture(scope="session")
def client():
    return TestClient(app)


@pytest.fixture(autouse=True)
def reset_limiters():
    login_limiter.reset()
    register_limiter.reset()


class Account:
    counter = 0

    def __init__(self, client):
        Account.counter += 1
        self.client = client
        self.username = f"kullanici{Account.counter}"
        self.email = f"{self.username}@example.com"
        self.password = "guclu-sifre-1"
        assert client.post("/api/users/register", json={
            "username": self.username, "email": self.email, "password": self.password
        }).status_code == 200
        self.login()

    def login(self):
        response = self.client.post("/api/users/login", json={"username": self.username, "password": self.password})
        assert response.status_code == 200
        self.token = response.json()["access_token"]

    @property
    def headers(self):
        return {"Authorization": f"Bearer {self.token}"}

    def get(self, path, **kwargs):
        return self.client.get(path, headers=self.headers, **kwargs)

    def post(self, path, **kwargs):
        return self.client.post(path, headers=self.headers, **kwargs)

    def put(self, path, **kwargs):
        return self.client.put(path, headers=self.headers, **kwargs)

    def delete(self, path, **kwargs):
        return self.client.request("DELETE", path, headers=self.headers, **kwargs)


@pytest.fixture
def account(client):
    return Account(client)


@pytest.fixture
def other_account(client):
    return Account(client)
