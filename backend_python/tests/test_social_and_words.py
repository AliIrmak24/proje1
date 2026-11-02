def test_friendship_needs_acceptance(account, other_account):
    assert account.post("/api/friends/add", json={"target_username": other_account.username}).json()["status"] == "pending"
    assert account.get("/api/friends/").json() == []
    assert account.post("/api/friends/add", json={"target_username": other_account.username}).status_code == 400

    requests = other_account.get("/api/friends/requests").json()
    assert requests[0]["sender"]["username"] == account.username
    assert account.post(f"/api/friends/requests/{requests[0]['request_id']}/accept").status_code == 404
    assert other_account.post(f"/api/friends/requests/{requests[0]['request_id']}/accept").status_code == 200
    assert len(account.get("/api/friends/").json()) == 1


def test_rejected_request_disappears(account, other_account):
    account.post("/api/friends/add", json={"target_username": other_account.username})
    request_id = other_account.get("/api/friends/requests").json()[0]["request_id"]
    assert other_account.delete(f"/api/friends/requests/{request_id}").status_code == 200
    assert account.get("/api/friends/search", params={"q": other_account.username}).json()[0]["friend_status"] == "none"


def test_mutual_request_accepts(account, other_account):
    account.post("/api/friends/add", json={"target_username": other_account.username})
    result = other_account.post("/api/friends/add", json={"target_username": account.username})
    assert result.json()["status"] == "accepted"


def test_user_search_does_not_match_email(account, other_account):
    assert account.get("/api/friends/search", params={"q": "example.com"}).json() == []


def test_user_search_treats_wildcards_literally(account, other_account):
    assert account.get("/api/friends/search", params={"q": "%"}).json() == []


def test_notes_are_upserted_per_word(account, other_account):
    note = {"word": "apple", "translation": "elma", "personal_note": "ilk"}
    first = account.post("/api/notes/add", json=note).json()
    second = account.post("/api/notes/add", json={**note, "personal_note": "ikinci"}).json()
    assert first["id"] == second["id"]
    assert [n["personal_note"] for n in account.get("/api/notes/my-notes").json()] == ["ikinci"]
    assert other_account.get("/api/notes/my-notes").json() == []
    assert other_account.delete(f"/api/notes/delete/{first['id']}").status_code == 404


def test_word_listing_is_paged_and_bounded(client):
    first = client.get("/api/words/?limit=10").json()
    second = client.get("/api/words/?limit=10&offset=10").json()
    assert len(first) == 10
    assert not {w["id"] for w in first} & {w["id"] for w in second}
    assert client.get("/api/words/?limit=0").status_code == 422
    assert client.get("/api/words/?limit=100000").status_code == 422


def test_search_finds_english_and_turkish(client):
    assert any(w["word"].lower() == "water" for w in client.get("/api/words/?search=water&limit=200").json())
    assert any(w["word"].lower() == "water" for w in client.get("/api/words/?search=su&limit=200").json())


def test_exact_search_treats_wildcards_literally(client):
    assert client.get("/api/words/search/%25").status_code == 404
    assert client.get("/api/words/search/___").status_code == 404


def test_counts_cover_all_levels(client):
    counts = client.get("/api/words/counts").json()
    assert set(counts) == {"A1", "A2", "B1", "B2", "C1", "C2"}
    assert all(count > 0 for count in counts.values())


def test_random_words_have_distinct_translations(client):
    words = client.get("/api/words/random?count=20").json()
    assert len({w["translation"] for w in words}) == len(words)
