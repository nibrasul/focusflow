import pytest
from datetime import datetime
from fastapi.testclient import TestClient
from app.main import app
from app.database.session import engine, SessionLocal
from app.database.base import Base
from app.services.achievements import AchievementService

@pytest.fixture(autouse=True, scope="module")
def setup_database():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    AchievementService.seed_achievements(db)
    db.close()

client = TestClient(app)

def test_health_endpoint():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"

def test_dashboard_endpoint():
    response = client.get("/api/v1/dashboard")
    assert response.status_code == 200
    data = response.json()
    assert "profile" in data
    assert "weekly_accuracy_trend" in data
    assert len(data["weekly_accuracy_trend"]) == 7

def test_achievements_list():
    response = client.get("/api/v1/achievements")
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 5
    assert any(a["id"] == "first_focus" for a in data)

def test_session_lifecycle():
    # 1. Create session
    create_payload = {
        "game_mode": "selective",
        "started_at": datetime.utcnow().isoformat(),
        "level": 1.5,
    }
    create_res = client.post("/api/v1/sessions", json=create_payload)
    assert create_res.status_code == 200
    session_data = create_res.json()
    session_id = session_data["id"]

    # 2. Complete session
    complete_payload = {
        "completed_at": datetime.utcnow().isoformat(),
        "duration": 45,
        "level": 1.5,
        "attempts": [
            {
                "round_number": 1,
                "target_type": "triangle",
                "player_action": "hit",
                "correct": True,
                "reaction_time": 420.0,
                "distraction_present": False,
            },
            {
                "round_number": 2,
                "target_type": "circle",
                "player_action": "hit",
                "correct": True,
                "reaction_time": 390.0,
                "distraction_present": False,
            },
            {
                "round_number": 3,
                "target_type": "square",
                "player_action": "miss",
                "correct": False,
                "reaction_time": 1200.0,
                "distraction_present": False,
            }
        ]
    }
    comp_res = client.post(f"/api/v1/sessions/{session_id}/complete", json=complete_payload)
    assert comp_res.status_code == 200
    comp_data = comp_res.json()
    assert comp_data["accuracy"] == 66.7
    assert comp_data["score"] > 0
    assert comp_data["missed_targets"] == 1
    assert comp_data["new_level"] is not None
