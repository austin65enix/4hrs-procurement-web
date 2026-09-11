$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================"
Write-Host "  4HRS Procurement - VERIFY"
Write-Host "========================================"
Write-Host ""

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $ProjectRoot

try {

    Write-Host "[1/6] Checking Docker runtime..."

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker CLI not found."
    }

    docker info *> $null

    if ($LASTEXITCODE -ne 0) {
        throw "Docker Engine is not available."
    }

    Write-Host "      Docker: PASS"

    Write-Host ""
    Write-Host "[2/6] Checking application container..."

    $ContainerId = docker compose ps -q procurement |
        Select-Object -First 1

    if ([string]::IsNullOrWhiteSpace($ContainerId)) {
        throw "Procurement container is not running."
    }

    $ContainerId = $ContainerId.Trim()

    $InspectJson = docker inspect $ContainerId

    if ($LASTEXITCODE -ne 0) {
        throw "docker inspect failed."
    }

    $Inspect = $InspectJson | ConvertFrom-Json

    if (-not $Inspect[0].State.Running) {
        throw "Procurement container is not running."
    }

    Write-Host "      Container: PASS"
    Write-Host "      ID: $($ContainerId.Substring(0,12))"

    Write-Host ""
    Write-Host "[3/6] Checking persistent storage..."

    $DataMount = $Inspect[0].Mounts |
        Where-Object { $_.Destination -eq "/app/data" } |
        Select-Object -First 1

    if (-not $DataMount) {
        throw "/app/data persistent mount not found."
    }

    if ([string]::IsNullOrWhiteSpace($DataMount.Name)) {
        throw "Named Docker volume not found."
    }

    Write-Host "      Volume: $($DataMount.Name)"
    Write-Host "      Persistent storage: PASS"

    Write-Host ""
    Write-Host "[4/6] Checking application health..."

    $Health = Invoke-RestMethod `
        -Uri "http://127.0.0.1:8000/healthz" `
        -Method Get `
        -TimeoutSec 5

    if ($Health.status -ne "ok") {
        throw "Application health endpoint did not return OK."
    }

    Write-Host "      Health: PASS"
    Write-Host "      Version: $($Health.version)"

    Write-Host ""
    Write-Host "[5/6] Checking SQLite integrity..."

    $IntegrityCode = @"
import sqlite3
import sys

db = "/app/data/procurement.db"

conn = sqlite3.connect(db)

try:
    result = conn.execute(
        "PRAGMA integrity_check"
    ).fetchone()[0]
finally:
    conn.close()

print("SQLITE_INTEGRITY=" + result.upper())

if result != "ok":
    sys.exit(1)
"@

    $IntegrityOutput = $IntegrityCode |
        docker exec -i $ContainerId python -

    if ($LASTEXITCODE -ne 0) {
        throw "SQLite integrity check failed."
    }

    $IntegrityOutput |
        ForEach-Object {
            Write-Host "      $_"
        }

    Write-Host "      Database: PASS"

    Write-Host ""
    Write-Host "[6/6] Checking procurement API..."

    $Requests = Invoke-RestMethod `
        -Uri "http://127.0.0.1:8000/requests" `
        -Method Get `
        -TimeoutSec 5

    $RequestCount = @($Requests).Count

    $Branch = git branch --show-current
    $Commit = git rev-parse HEAD

    Write-Host "      Requests: $RequestCount"
    Write-Host "      API: PASS"

    Write-Host ""
    docker compose ps

    Write-Host ""
    Write-Host "========================================"
    Write-Host "  4HRS SYSTEM HEALTHY"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "DOCKER=PASS"
    Write-Host "CONTAINER=PASS"
    Write-Host "PERSISTENT_VOLUME=PASS"
    Write-Host "HTTP_HEALTH=PASS"
    Write-Host "SQLITE_INTEGRITY=PASS"
    Write-Host "PROCUREMENT_API=PASS"
    Write-Host "REQUEST_COUNT=$RequestCount"
    Write-Host "APP_VERSION=$($Health.version)"
    Write-Host "GIT_BRANCH=$Branch"
    Write-Host "GIT_COMMIT=$Commit"
    Write-Host ""
    Write-Host "RESULT=PASS"
}
catch {

    Write-Host ""
    Write-Host "========================================"
    Write-Host "  4HRS VERIFY FAILED"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "ERROR=$($_.Exception.Message)"
    Write-Host "RESULT=FAIL"

    exit 1
}
finally {
    Pop-Location
}
