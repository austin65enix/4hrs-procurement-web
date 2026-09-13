from pathlib import Path
import sqlite3

from fastapi import FastAPI


APP_VERSION = "0.1.0"
SCENARIO_ID = "medical-review"

BASE_DIR = Path(__file__).resolve().parent.parent
DB_PATH = BASE_DIR / "data" / "medical.db"


app = FastAPI(
    title="4HRS Medical Review",
    version=APP_VERSION
)


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    DB_PATH.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    with get_db() as conn:

        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS medical_reviews (
                id INTEGER PRIMARY KEY AUTOINCREMENT,

                requester TEXT NOT NULL,
                department TEXT NOT NULL,
                case_reference TEXT NOT NULL,

                request_type TEXT NOT NULL,

                priority TEXT NOT NULL
                    CHECK (
                        priority IN (
                            'ROUTINE',
                            'PRIORITY'
                        )
                    ),

                summary TEXT NOT NULL,

                status TEXT NOT NULL
                    CHECK (
                        status IN (
                            'PENDING_REVIEW',
                            'ACCEPTED',
                            'RETURNED'
                        )
                    ),

                created_at TEXT NOT NULL,

                decided_at TEXT,
                decided_by TEXT,
                decision_note TEXT
            )
            """
        )

        conn.execute(
            """
            CREATE UNIQUE INDEX IF NOT EXISTS
                idx_medical_reviews_case_reference
            ON medical_reviews(case_reference)
            """
        )

        conn.commit()


init_db()


@app.get("/")
def root():
    return {
        "service": "4HRS Medical Review",
        "scenario_id": SCENARIO_ID,
        "phase": "P06-M3-A"
    }


@app.get("/healthz")
def healthz():
    return {
        "status": "ok",
        "service": SCENARIO_ID,
        "version": APP_VERSION,
        "phase": "P06-M3-A"
    }