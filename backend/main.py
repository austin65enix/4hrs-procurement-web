from datetime import datetime, timezone
from pathlib import Path
import sqlite3

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

app = FastAPI(
    title="4HRS Procurement Web",
    version="0.3.0"
)

BASE_DIR = Path(__file__).resolve().parent.parent
DB_PATH = BASE_DIR / "data" / "procurement.db"


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    with get_db() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS purchase_requests (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                applicant TEXT NOT NULL,
                item_name TEXT NOT NULL,
                quantity INTEGER NOT NULL,
                unit_price REAL NOT NULL,
                total_amount REAL NOT NULL,
                status TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
        """)


init_db()


class PurchaseRequestCreate(BaseModel):
    applicant: str = Field(min_length=1)
    item_name: str = Field(min_length=1)
    quantity: int = Field(gt=0)
    unit_price: float = Field(gt=0)


@app.get("/")
def root():
    return FileResponse(BASE_DIR / "frontend" / "index.html")


@app.get("/healthz")
def healthz():
    return {"status": "ok", "version": "0.3.0"}


@app.get("/requests")
def list_requests():
    with get_db() as conn:
        rows = conn.execute(
            "SELECT * FROM purchase_requests ORDER BY id DESC"
        ).fetchall()
    return [dict(row) for row in rows]


@app.post("/requests")
def create_request(request: PurchaseRequestCreate):
    total = request.quantity * request.unit_price
    created_at = datetime.now(timezone.utc).isoformat()

    with get_db() as conn:
        cur = conn.execute("""
            INSERT INTO purchase_requests
            (applicant,item_name,quantity,unit_price,total_amount,status,created_at)
            VALUES (?,?,?,?,?,?,?)
        """, (
            request.applicant,
            request.item_name,
            request.quantity,
            request.unit_price,
            total,
            "PENDING",
            created_at
        ))
        conn.commit()

    return {"id": cur.lastrowid, "status": "PENDING"}


def change_status(request_id: int, new_status: str):
    with get_db() as conn:
        row = conn.execute(
            "SELECT status FROM purchase_requests WHERE id=?",
            (request_id,)
        ).fetchone()

        if row is None:
            raise HTTPException(404, "Request not found")

        if row["status"] != "PENDING":
            raise HTTPException(409, "Request already decided")

        conn.execute(
            "UPDATE purchase_requests SET status=? WHERE id=?",
            (new_status, request_id)
        )
        conn.commit()

    return {"id": request_id, "status": new_status}


@app.post("/requests/{request_id}/approve")
def approve_request(request_id: int):
    return change_status(request_id, "APPROVED")


@app.post("/requests/{request_id}/reject")
def reject_request(request_id: int):
    return change_status(request_id, "REJECTED")
