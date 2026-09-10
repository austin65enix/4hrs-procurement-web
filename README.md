# 4HRS Procurement Web

A lightweight procurement approval MVP built as part of the **4HRS Rapid Application Development Exercise**.

The project demonstrates how a small business workflow application can be built quickly on a standard Windows environment using a minimal technology stack.

---

## Overview

**4HRS Procurement Web** provides a simple procurement request and approval workflow.

The MVP focuses on a business flow that ordinary users can immediately understand:

```text
Create Request
      ↓
   PENDING
    ↙   ↘
APPROVED REJECTED
      ↓
Dashboard Update
```

The project intentionally starts with a simple native Windows development environment.

Docker, WSL, Kubernetes, authentication, and enterprise infrastructure are not required for the initial MVP.

---

## Features

The current MVP includes:

- Create procurement requests
- Store requests in SQLite
- Display procurement request list
- Automatic total amount calculation
- PENDING request status
- Approve procurement requests
- Reject procurement requests
- Prevent repeated decisions after approval or rejection
- Dashboard counters
  - Total requests
  - Pending requests
  - Approved requests
  - Rejected requests
- Responsive browser UI
- FastAPI REST backend
- Automatic OpenAPI / Swagger documentation
- Native Windows development workflow

---

## MVP Workflow

A new procurement request starts in the `PENDING` state.

```text
NEW REQUEST
     │
     ▼
  PENDING
   │   │
   │   └─────────────┐
   ▼                 ▼
APPROVED          REJECTED
```

Once a request becomes `APPROVED` or `REJECTED`, it cannot be decided again.

---

## Technology Stack

### Backend

- Python 3.12
- FastAPI
- Uvicorn
- SQLite
- Pydantic

### Frontend

- HTML
- CSS
- Vanilla JavaScript

### Development

- Windows
- PowerShell
- Visual Studio Code
- Git

The MVP does **not** require:

- Node.js
- Docker
- WSL
- Kubernetes
- External database server

---

## Project Structure

```text
procurement-web/
│
├─ backend/
│  ├─ __init__.py
│  └─ main.py
│
├─ frontend/
│  └─ index.html
│
├─ data/
│  └─ procurement.db
│
├─ .gitignore
├─ requirements.txt
├─ run.ps1
└─ README.md
```

`data/procurement.db` is created at runtime and is not committed to Git.

---

## Requirements

Recommended environment:

```text
Windows 10 / Windows 11
Python 3.12+
Git
Modern Web Browser
```

The validated development environment used:

```text
Python 3.12.10
FastAPI 0.141.1
Uvicorn 0.52.4
Git 2.55.0
Visual Studio Code 1.137.0
```

---

## Quick Start

### 1. Clone the repository

```powershell
git clone <repository-url>
cd 4hrs-procurement-web
```

If you are running the project from an existing local copy, simply enter the project directory.

```powershell
cd $HOME\4HRS\procurement-web
```

---

### 2. Create a Python virtual environment

```powershell
python -m venv .venv
```

Activate it:

```powershell
.\.venv\Scripts\Activate.ps1
```

The PowerShell prompt should become similar to:

```text
(.venv) PS C:\Users\<user>\4HRS\procurement-web>
```

---

### 3. Install dependencies

```powershell
python -m pip install -r requirements.txt
```

Current dependencies:

```text
fastapi==0.141.1
uvicorn==0.52.4
```

---

### 4. Start the application

Using the provided PowerShell script:

```powershell
.\run.ps1
```

Or start Uvicorn directly:

```powershell
python -m uvicorn backend.main:app --host 127.0.0.1 --port 8000
```

Expected output:

```text
Application startup complete.
Uvicorn running on http://127.0.0.1:8000
```

---

## Open the Application

Open a browser and visit:

```text
http://127.0.0.1:8000/
```

The main page provides:

- Procurement request form
- Procurement request list
- Approval and rejection actions
- Dashboard counters

---

## API Documentation

FastAPI automatically provides Swagger / OpenAPI documentation.

Open:

```text
http://127.0.0.1:8000/docs
```

Health check:

```text
http://127.0.0.1:8000/healthz
```

Expected response:

```json
{
  "status": "ok",
  "version": "0.3.0"
}
```

---

## API Endpoints

### Health

```text
GET /healthz
```

### List Procurement Requests

```text
GET /requests
```

### Create Procurement Request

```text
POST /requests
```

Example request:

```json
{
  "applicant": "Austin",
  "item_name": "VAIO 32GB",
  "quantity": 1,
  "unit_price": 46999
}
```

A newly created request receives:

```text
PENDING
```

status.

### Approve Request

```text
POST /requests/{request_id}/approve
```

State transition:

```text
PENDING → APPROVED
```

### Reject Request

```text
POST /requests/{request_id}/reject
```

State transition:

```text
PENDING → REJECTED
```

---

## MVP Validation

The initial MVP was tested using two procurement requests.

### Test Case 1

```text
Request #1
Item: VAIO 32GB
Amount: NT$46,999

PENDING
   ↓
APPROVED
```

Result:

```text
PASS
```

### Test Case 2

```text
Request #2
Item: VAIO 32GB
Amount: NT$46,999

PENDING
   ↓
REJECTED
```

Result:

```text
PASS
```

---

## Validation Status

```text
CREATE_REQUEST=PASS

REQUEST_LIST=PASS

SQLITE_PERSISTENCE=PASS

PENDING_STATE=PASS

PENDING_TO_APPROVED=PASS

PENDING_TO_REJECTED=PASS

DASHBOARD_UPDATE=PASS

APPROVAL_UI=PASS

APPROVAL_BACKEND=PASS

MVP_CORE_FLOW=PASS
```

---

## 4HRS Development Approach

The project follows a simple principle:

> **Show the working product first, explain the technology second.**

Instead of starting the demonstration with database schemas, JSON, or API details, the user first sees:

```text
Create Request
      ↓
Request Appears
      ↓
Approve / Reject
      ↓
Dashboard Changes
```

This makes the workflow easier for non-technical users to understand.

Technical components such as FastAPI, SQLite, REST APIs, and state transitions can then be explained after the business workflow is visible.

---

## Development Phases

### P01 — Procurement Web MVP

Status:

```text
CLOSED_COMPLETE
```

Scope:

```text
Request Creation
Request List
SQLite Persistence
Approval
Rejection
Dashboard
Browser UI
```

### Future Extensions

Possible future phases include:

```text
P02
Containerized Reproducibility

P03
Authentication and Role-Based Access Control

P04
Audit Trail and Approval Evidence

P05
External Deployment

P06
Workflow / BPM Integration

P07
Governance and Execution Controls
```

---

## Out of Scope for P01

The following features are intentionally excluded from the first MVP:

- User authentication
- SSO
- Role-based access control
- Multiple approval levels
- Purchase order generation
- Supplier management
- Attachment upload
- Email notifications
- Full audit event history
- PostgreSQL
- Docker
- WSL
- Kubernetes
- Cloud deployment
- Production security hardening

These can be introduced gradually without increasing the complexity of the initial 4HRS demonstration.

---

## Git Baseline

The initial functional MVP baseline was committed to Git after successful approval and rejection testing.

```text
Branch:
main
```

Initial MVP baseline:

```text
e54d3db
4HRS Procurement MVP core flow complete
```

Runtime files such as the Python virtual environment and SQLite database are excluded from source control.

---

## Git Ignore Policy

The project excludes local runtime artifacts:

```gitignore
.venv/
__pycache__/
*.pyc
data/*.db
*.sqlite
*.sqlite3
```

This keeps the repository focused on source code and reproducible configuration.

---

## Design Goal

4HRS Procurement Web is not intended to be a complete enterprise procurement platform.

Its purpose is to demonstrate that a recognizable business workflow can move from:

```text
Idea
 ↓
Application
 ↓
Working UI
 ↓
Persistent Data
 ↓
Approval Workflow
 ↓
Validated MVP
```

within a short development cycle.

---

## Project Status

```text
PROJECT=4HRS-PROCUREMENT-WEB-P01

ENVIRONMENT=WINDOWS_NATIVE

BACKEND=FASTAPI

DATABASE=SQLITE

FRONTEND=HTML_CSS_JAVASCRIPT

CREATE_REQUEST=PASS

APPROVE=PASS

REJECT=PASS

MVP_CORE_FLOW=PASS

SOURCE_BASELINE_SEALED=YES

P01_STATUS=CLOSED_COMPLETE
```

---

## License

License has not yet been assigned.

---

## Author

**Austin Hsieh**

GitHub:

```text
austin65enix
```

Project:

```text
4HRS Procurement Web
```