# FocusFlow: Concentration & Attention Training

A high-performance, scientifically-grounded mobile attention training platform built with **Flutter (iOS)** and backed by an authoritative **Python (FastAPI)** cognitive backend and **PostgreSQL 16**.

## 📱 5 Cognitive Training Modes
1. **Mode 1 — Selective Focus**: Conjunction visual search requiring the player to locate a designated target shape among feature-overlapping distractors.
2. **Mode 2 — Sustained Focus**: Continuous Performance Test (CPT / Go/No-Go) with unpredictable inter-stimulus intervals (600ms–1100ms) requiring sustained vigilance.
3. **Mode 3 — Distraction Shield**: Resistance to distraction under moving peripheral animations, flashing background tints, and deceptive fake instruction banners.
4. **Mode 4 — Rule Switch**: Cognitive flexibility and task-switching measuring reaction time and switch cost across dynamically shifting classification rules.
5. **Mode 5 — Memory Focus**: Sequenced working-memory span reproduction (3 to 6 items based on difficulty level).
6. **Daily Focus Session**: Multi-stage integrated training routine chaining all 5 modes.

---

## 🏗 Project Architecture
```
Games/
├── backend/                  # Python FastAPI Backend
│   ├── app/
│   │   ├── api/v1/           # REST APIs (sessions, dashboard, achievements, difficulty)
│   │   ├── core/             # Settings and environment configs
│   │   ├── database/         # PostgreSQL connection & SQLAlchemy ORM
│   │   ├── models/           # DB Models (User, Profile, GameSession, GameAttempt, Achievement)
│   │   ├── schemas/          # Pydantic schemas
│   │   └── services/         # Authoritative scoring, adaptive difficulty, analytics
│   ├── tests/                # Automated pytest suite (13 tests)
│   ├── Dockerfile            # Production container
│   ├── render.yaml           # 1-click cloud blueprint with PostgreSQL
│   └── requirements.txt
│
└── mobile/                   # Flutter iOS Application
    ├── lib/
    │   ├── core/             # Theme, SQLite AppDatabase, SyncManager, ApiClient
    │   ├── domain/           # 5 Cognitive Game Engines, Local Scoring, Data Models
    │   └── presentation/     # Clean light iOS UI (Onboarding, Dashboard, Game, Results, Progress, Settings)
    ├── test/                 # Automated Flutter test suite (10 tests)
    └── ios/                  # Configured iOS Runner with portrait lock and networking
```

---

## 🚀 Getting Started

### 1. Backend Setup
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Run automated tests
pytest tests/

# Start development server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Mobile App Setup
```bash
cd mobile
flutter pub get

# Run tests & analyzer
flutter analyze
flutter test

# Run on iOS Device or Simulator
flutter run
```

---

## 🛡 Disclaimer
Attention and concentration training through interactive gameplay. Metrics represent actual in-game performance. Does not diagnose ADHD, cure attention disorders, or make unsupported clinical claims.
