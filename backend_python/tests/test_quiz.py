from app.database import SessionLocal
from app.models.quiz import UserWordProgress, utcnow
from app.services.quiz_service import QuizService


def start_quiz(account, query="count=5"):
    response = account.get(f"/api/quiz/questions?{query}")
    assert response.status_code == 200
    return response.json()


def answer(account, session_id, question_id, index):
    return account.post("/api/quiz/answer", json={
        "session_id": session_id, "question_id": question_id, "selected_index": index
    }).json()


def test_questions_need_login_and_hide_answers(client, account):
    assert client.get("/api/quiz/questions").status_code == 401
    quiz = start_quiz(account)
    assert len(quiz["questions"]) == 5
    assert all("correct_index" not in q and len(q["options"]) == 4 for q in quiz["questions"])
    assert all(len(set(q["options"])) == 4 for q in quiz["questions"])


def test_count_is_bounded(account):
    assert account.get("/api/quiz/questions?count=-1").status_code == 422
    assert account.get("/api/quiz/questions?count=100000").status_code == 422


def test_level_filter(account):
    quiz = start_quiz(account, "count=10&level=B2")
    assert {q["level"] for q in quiz["questions"]} == {"B2"}


def test_claimed_score_is_ignored(account):
    assert account.post("/api/quiz/submit", json={"correct_answers": 1000000}).status_code == 422


def test_xp_comes_from_recorded_answers(account):
    quiz = start_quiz(account)
    session_id = quiz["session_id"]
    correct = answer(account, session_id, 1, 0)["correct_index"]
    second = answer(account, session_id, 2, 0)

    # İlk cevap sonrası öğrenilen doğru şık sonucu değiştirmez
    repeated = answer(account, session_id, 1, correct)
    assert repeated["correct"] is (correct == 0)

    expected = sum([correct == 0, second["correct"]]) * 10
    result = account.post("/api/quiz/submit", json={"session_id": session_id})
    assert result.status_code == 200
    assert result.json()["earned_xp"] == expected
    assert len(result.json()["review"]) == 5 - expected // 10

    assert account.post("/api/quiz/submit", json={"session_id": session_id}).status_code == 400


def test_session_belongs_to_owner(account, other_account):
    session_id = start_quiz(account)["session_id"]
    assert other_account.post("/api/quiz/submit", json={"session_id": session_id}).status_code == 400


def test_activity_is_capped(account):
    response = account.post("/api/quiz/activity", json={"activity": "matching", "correct_answers": 1000000})
    assert response.json()["earned_xp"] == 60

    earned = [
        account.post("/api/quiz/activity", json={"activity": "mini_quiz", "correct_answers": 1}).json()["earned_xp"]
        for _ in range(25)
    ]
    assert sum(earned) == 100


def test_placement_sets_level_without_xp(account):
    test = account.get("/api/quiz/placement").json()
    assert len(test["questions"]) == 18

    for question in test["questions"]:
        answer(account, test["session_id"], question["id"], 0)

    result = account.post("/api/quiz/submit", json={"session_id": test["session_id"]}).json()
    assert result["earned_xp"] == 0
    assert result["placement_level"] in ("A1", "A2", "B1", "B2", "C1", "C2")
    assert account.get("/api/users/me").json()["cefr_level"] == result["placement_level"]


def test_placement_level_stops_at_first_failed_level():
    levels = [level for level in ("A1", "A2", "B1", "B2", "C1", "C2") for _ in range(3)]
    flags = [True] * 3 + [True, True, False] + [False] * 3 + [True] * 9
    assert QuizService()._placement_level(levels, flags) == "A2"
    assert QuizService()._placement_level(levels, [False] * 18) == "A1"
    assert QuizService()._placement_level(levels, [True] * 18) == "C2"


def test_review_schedule_and_xp(account):
    item = account.get("/api/learn/session?limit=1").json()[0]
    word_id = item["word"]["id"]
    assert item["is_new"] is True

    first = account.post("/api/learn/review", json={"word_id": word_id, "known": True}).json()
    assert first["earned_xp"] == 10
    assert first["box"] == 1

    # Tekrar zamanı gelmeden işaretlemek XP ve kutu kazandırmaz
    repeat = account.post("/api/learn/review", json={"word_id": word_id, "known": True}).json()
    assert repeat["earned_xp"] == 0
    assert repeat["box"] == 1

    forgot = account.post("/api/learn/review", json={"word_id": word_id, "known": False}).json()
    assert forgot["box"] == 0


def test_due_words_return_first(account):
    word_id = account.get("/api/learn/session?limit=1").json()[0]["word"]["id"]
    account.post("/api/learn/review", json={"word_id": word_id, "known": True})
    assert word_id not in [i["word"]["id"] for i in account.get("/api/learn/session?limit=30").json() if not i["is_new"]]

    with SessionLocal() as db:
        db.query(UserWordProgress).filter(UserWordProgress.word_id == word_id).update({"next_review": utcnow()})
        db.commit()

    first = account.get("/api/learn/session?limit=5").json()[0]
    assert first["word"]["id"] == word_id
    assert first["is_new"] is False


def test_stats_reflect_real_activity(account):
    empty = account.get("/api/learn/stats").json()
    assert empty["learned_words"] == 0
    assert empty["streak_days"] == 0
    assert empty["total_quizzes"] == 0

    word_id = account.get("/api/learn/session?limit=1").json()[0]["word"]["id"]
    account.post("/api/learn/review", json={"word_id": word_id, "known": True})
    quiz = start_quiz(account)
    account.post("/api/quiz/submit", json={"session_id": quiz["session_id"]})

    stats = account.get("/api/learn/stats").json()
    assert stats["streak_days"] == 1
    assert stats["total_quizzes"] == 1
    assert stats["words_today"] == 1
    assert len(stats["activity"]) == 7
    assert stats["activity"][-1]["xp"] == 10
