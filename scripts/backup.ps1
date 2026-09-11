$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================"
Write-Host "  4HRS Procurement - BACKUP"
Write-Host "========================================"
Write-Host ""

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $ProjectRoot

try {
    Write-Host "[1/5] Checking application container..."

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker CLI not found."
    }

    $ContainerId = (docker compose ps -q procurement).Trim()

    if (-not $ContainerId) {
        throw "Procurement container is not running."
    }

    Write-Host "      Container: PASS"

    Write-Host ""
    Write-Host "[2/5] Creating consistent SQLite snapshot..."

    $PythonBackup = @'
import sqlite3
import sys

source = "/app/data/procurement.db"
target = "/tmp/procurement-backup.db"

src = sqlite3.connect(source)
dst = sqlite3.connect(target)

try:
    src.backup(dst)
finally:
    dst.close()
    src.close()

check = sqlite3.connect(target)
result = check.execute("PRAGMA integrity_check").fetchone()[0]
check.close()

if result != "ok":
    print("SQLITE_INTEGRITY=FAIL")
    sys.exit(1)

print("SQLITE_BACKUP=PASS")
print("SQLITE_INTEGRITY=PASS")
'@

    $PythonBackup | docker exec -i $ContainerId python -

    if ($LASTEXITCODE -ne 0) {
        throw "SQLite backup operation failed."
    }

    Write-Host ""
    Write-Host "[3/5] Exporting backup to host..."

    $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    $BackupRoot = Join-Path $ProjectRoot "backups"
    $BackupDir  = Join-Path $BackupRoot $Timestamp

    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

    $BackupDb = Join-Path $BackupDir "procurement.db"

    docker cp "${ContainerId}:/tmp/procurement-backup.db" $BackupDb

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to copy backup from container."
    }

    if (-not (Test-Path $BackupDb)) {
        throw "Backup file was not created."
    }

    Write-Host "      Export: PASS"

    Write-Host ""
    Write-Host "[4/5] Generating evidence..."

    $Hash = (Get-FileHash `
        -Path $BackupDb `
        -Algorithm SHA256).Hash

    $Size = (Get-Item $BackupDb).Length

    try {
        $Requests = Invoke-RestMethod `
            -Uri "http://127.0.0.1:8000/requests" `
            -Method Get

        $RequestCount = @($Requests).Count
    }
    catch {
        $RequestCount = -1
    }

    $Branch = git branch --show-current
    $Commit = git rev-parse HEAD

    $Manifest = [ordered]@{
        project       = "4HRS Procurement Web"
        backup_time   = (Get-Date).ToString("o")
        source        = "/app/data/procurement.db"
        backup_file   = "procurement.db"
        sha256        = $Hash
        size_bytes    = $Size
        request_count = $RequestCount
        git_branch    = $Branch
        git_commit    = $Commit
        integrity     = "PASS"
    }

    $ManifestPath = Join-Path $BackupDir "manifest.json"

    $Manifest |
        ConvertTo-Json |
        Set-Content `
            -Path $ManifestPath `
            -Encoding UTF8

    docker exec $ContainerId `
        rm -f /tmp/procurement-backup.db *> $null

    Write-Host "      SHA256: $Hash"
    Write-Host "      Request count: $RequestCount"
    Write-Host "      Manifest: PASS"

    Write-Host ""
    Write-Host "[5/5] Backup complete..."

    Write-Host ""
    Write-Host "========================================"
    Write-Host "  4HRS BACKUP COMPLETE"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Backup:"
    Write-Host $BackupDb
    Write-Host ""
    Write-Host "Manifest:"
    Write-Host $ManifestPath
    Write-Host ""
    Write-Host "SHA256=$Hash"
    Write-Host "RESULT=PASS"
}
catch {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  4HRS BACKUP FAILED"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "ERROR=$($_.Exception.Message)"
    Write-Host "RESULT=FAIL"

    exit 1
}
finally {
    Pop-Location
}