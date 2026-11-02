from app.core.rate_limit import login_limiter
from app.services.user_service import UserService


def test_public_leaderboards_expose_only_public_fields(client, account):
    for path in ("/api/leaderboard", "/api/quiz/leaderboard"):
        rows = client.get(path).json()
        assert rows and all(set(row) == {"username", "xp", "level"} for row in rows)


def test_old_test_token_is_rejected(client):
    response = client.get("/api/users/me", headers={"Authorization": "Bearer test_admin_token_999"})
    assert response.status_code == 401


def test_plain_text_password_never_matches():
    service = UserService()
    assert service.verify_password("demo_hashed_password", "demo_hashed_password") is False
    assert service.verify_password("a" * 100, service.get_password_hash("abcdefgh")) is False


def test_registration_rejects_bad_input_with_readable_message(client):
    cases = [
        {"username": "", "email": "a@example.com", "password": "guclu-sifre-1"},
        {"username": "uygun", "email": "gecersiz", "password": "guclu-sifre-1"},
        {"username": "uygun", "email": "a@example.com", "password": "kisa"},
        {"username": "uygun", "email": "a@example.com", "password": "x" * 73},
    ]
    for body in cases:
        response = client.post("/api/users/register", json=body)
        assert response.status_code == 422
        assert isinstance(response.json()["detail"], str)


def test_session_survives_email_change(account):
    assert account.put("/api/users/me", json={"email": f"yeni-{account.email}"}).status_code == 200
    assert account.get("/api/users/me").status_code == 200


def test_duplicate_username_is_reported(account, other_account):
    response = account.put("/api/users/me", json={"username": other_account.username})
    assert response.status_code == 400


def test_password_change_invalidates_old_tokens(account):
    old_headers = account.headers
    response = account.post("/api/users/change-password", json={
        "old_password": account.password, "new_password": "yepyeni-sifre-2"
    })
    assert response.status_code == 200
    assert account.client.get("/api/users/me", headers=old_headers).status_code == 401

    account.token = response.json()["access_token"]
    assert account.get("/api/users/me").status_code == 200


def test_logout_invalidates_token(account):
    assert account.post("/api/users/logout").status_code == 200
    assert account.get("/api/users/me").status_code == 401


def test_login_is_rate_limited(client, account):
    body = {"username": account.username, "password": "yanlis-sifre"}
    statuses = [client.post("/api/users/login", json=body).status_code for _ in range(login_limiter.max_attempts + 1)]
    assert statuses[:-1] == [401] * login_limiter.max_attempts
    assert statuses[-1] == 429


def test_account_deletion_removes_user_data(account, other_account):
    other_account.post("/api/friends/add", json={"target_username": account.username})
    account.post("/api/notes/add", json={"word": "apple", "translation": "elma"})

    assert account.delete("/api/users/me", json={"password": "yanlis"}).status_code == 400
    assert account.delete("/api/users/me", json={"password": account.password}).status_code == 200
    assert account.get("/api/users/me").status_code == 401
    assert account.client.post("/api/users/login", json={
        "username": account.username, "password": account.password
    }).status_code == 401
    assert other_account.get("/api/friends/search", params={"q": account.username}).json() == []
