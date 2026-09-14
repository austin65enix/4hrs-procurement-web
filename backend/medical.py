from datetime import datetime, timezone
from pathlib import Path
import sqlite3
from typing import Literal

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field


APP_VERSION = "0.3.0"
SCENARIO_ID = "medical-review"
PHASE = "P06-M3-C"

BASE_DIR = Path(__file__).resolve().parent.parent
DB_PATH = BASE_DIR / "data" / "medical.db"
MEDICAL_UI_PATH = BASE_DIR / "frontend" / "medical.html"


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


class MedicalReviewCreate(BaseModel):

    requester: str = Field(
        min_length=1,
        max_length=100
    )

    department: str = Field(
        min_length=1,
        max_length=100
    )

    case_reference: str = Field(
        min_length=1,
        max_length=100
    )

    request_type: str = Field(
        min_length=1,
        max_length=150
    )

    priority: Literal[
        "ROUTINE",
        "PRIORITY"
    ]

    summary: str = Field(
        min_length=1,
        max_length=1000
    )


class DecisionMetadata(BaseModel):

    decided_by: str = Field(
        min_length=1,
        max_length=100
    )

    decision_note: str = Field(
        min_length=1,
        max_length=500
    )


def require_text(
    value: str,
    field_name: str
):
    cleaned = value.strip()

    if not cleaned:
        raise HTTPException(
            422,
            f"{field_name} must not be blank"
        )

    return cleaned


@app.get("/")
def root():
    return {
        "service": "4HRS Medical Review",
        "scenario_id": SCENARIO_ID,
        "phase": PHASE
    }


@app.get("/workspace", include_in_schema=False)
def workspace():

    if not MEDICAL_UI_PATH.exists():
        raise HTTPException(
            503,
            "Medical workspace unavailable"
        )

    return FileResponse(
        MEDICAL_UI_PATH
    )


@app.get("/healthz")
def healthz():
    return {
        "status": "ok",
        "service": SCENARIO_ID,
        "version": APP_VERSION,
        "phase": PHASE
    }


@app.get("/reviews")
def list_reviews():

    with get_db() as conn:

        rows = conn.execute(
            """
            SELECT *
            FROM medical_reviews
            ORDER BY id DESC
            """
        ).fetchall()

    return [
        dict(row)
        for row in rows
    ]


@app.get("/reviews/{review_id}")
def get_review(
    review_id: int
):

    with get_db() as conn:

        row = conn.execute(
            """
            SELECT *
            FROM medical_reviews
            WHERE id=?
            """,
            (review_id,)
        ).fetchone()

    if row is None:
        raise HTTPException(
            404,
            "Review not found"
        )

    return dict(row)


@app.post("/reviews")
def create_review(
    review: MedicalReviewCreate
):

    requester = require_text(
        review.requester,
        "requester"
    )

    department = require_text(
        review.department,
        "department"
    )

    case_reference = require_text(
        review.case_reference,
        "case_reference"
    )

    request_type = require_text(
        review.request_type,
        "request_type"
    )

    summary = require_text(
        review.summary,
        "summary"
    )

    created_at = (
        datetime.now(
            timezone.utc
        ).isoformat()
    )

    with get_db() as conn:

        existing = conn.execute(
            """
            SELECT id
            FROM medical_reviews
            WHERE case_reference=?
            """,
            (case_reference,)
        ).fetchone()

        if existing is not None:
            raise HTTPException(
                409,
                "case_reference already exists"
            )

        try:

            cur = conn.execute(
                """
                INSERT INTO medical_reviews (
                    requester,
                    department,
                    case_reference,
                    request_type,
                    priority,
                    summary,
                    status,
                    created_at
                )
                VALUES (
                    ?, ?, ?, ?, ?, ?, ?, ?
                )
                """,
                (
                    requester,
                    department,
                    case_reference,
                    request_type,
                    review.priority,
                    summary,
                    "PENDING_REVIEW",
                    created_at
                )
            )

            conn.commit()

        except sqlite3.IntegrityError:

            raise HTTPException(
                409,
                "case_reference already exists"
            )

    return {
        "id": cur.lastrowid,
        "case_reference": case_reference,
        "status": "PENDING_REVIEW",
        "created_at": created_at
    }


def change_status(
    review_id: int,
    new_status: str,
    metadata: DecisionMetadata
):

    decided_by = require_text(
        metadata.decided_by,
        "decided_by"
    )

    decision_note = require_text(
        metadata.decision_note,
        "decision_note"
    )

    with get_db() as conn:

        row = conn.execute(
            """
            SELECT status
            FROM medical_reviews
            WHERE id=?
            """,
            (review_id,)
        ).fetchone()

        if row is None:
            raise HTTPException(
                404,
                "Review not found"
            )

        if row["status"] != "PENDING_REVIEW":
            raise HTTPException(
                409,
                "Review already decided"
            )

        decided_at = (
            datetime.now(
                timezone.utc
            ).isoformat()
        )

        cur = conn.execute(
            """
            UPDATE medical_reviews
            SET
                status=?,
                decided_at=?,
                decided_by=?,
                decision_note=?
            WHERE
                id=?
                AND status='PENDING_REVIEW'
            """,
            (
                new_status,
                decided_at,
                decided_by,
                decision_note,
                review_id
            )
        )

        if cur.rowcount != 1:
            raise HTTPException(
                409,
                "Review state changed"
            )

        conn.commit()

    return {
        "id": review_id,
        "status": new_status,
        "decided_at": decided_at,
        "decided_by": decided_by,
        "decision_note": decision_note
    }


@app.post("/reviews/{review_id}/accept")
def accept_review(
    review_id: int,
    metadata: DecisionMetadata
):

    return change_status(
        review_id,
        "ACCEPTED",
        metadata
    )


@app.post("/reviews/{review_id}/return")
def return_review(
    review_id: int,
    metadata: DecisionMetadata
):

    return change_status(
        review_id,
        "RETURNED",
        metadata
    )