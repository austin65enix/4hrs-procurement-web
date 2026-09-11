param(
    [string]$BackupDir,
    [switch]$VerifyOnly,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================"
Write-Host "  4HRS Procurement - RECOVER"
Write-Host "========================================"
Write-Host ""

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $ProjectRoot

try {
    #
    # STEP 1 - Select backup
    #
    Write-Host "[1/6] Selecting backup..."

    $BackupRoot = Join-Path $ProjectRoot "backups"

    if (-not $BackupDir) {
        if (-not (Test-Path $BackupRoot)) {
            throw "Backup directory does not exist."
        }

        $Latest = Get-ChildItem $BackupRoot -Directory |
            Sort-Object Name -Descending |
            Select-Object -First 1

        if (-not $Latest) {
            throw "No backup was found."
        }

        $BackupDir = $Latest.FullName
    }
    else {
        $BackupDir = (Resolve-Path $BackupDir).Path
    }

    $BackupDb    = Join-Path $BackupDir "procurement.db"
    $ManifestPath = Join-Path $BackupDir "manifest.json"

    if (-not (Test-Path $BackupDb)) {
        throw "procurement.db not found in backup."
    }

    if (-not (Test-Path $ManifestPath)) {
        throw "manifest.json not found in backup."
    }

    Write-Host "      Backup:"
    Write-Host "      $BackupDir"
    Write-Host "      Selection: PASS"

    #
    # STEP 2 - Validate backup evidence
    #
    Write-Host ""
    Write-Host "[2/6] Validating backup evidence..."

    $Manifest = Get-Content $ManifestPath -Raw |
        ConvertFrom-Json

    $ActualHash = (
        Get-FileHash `
            -Path $BackupDb `
            -Algorithm SHA256
    ).Hash

    $ExpectedHash = $Manifest.sha256

    if (-not $ExpectedHash) {
        throw "SHA256 is missing from manifest."
    }

    if ($ActualHash -ne $ExpectedHash) {
        throw "Backup SHA256 does not match manifest."
    }

    if ($Manifest.integrity -ne "PASS") {
        throw "Backup manifest does not contain integrity=PASS."
    }

    Write-Host "      SHA256: PASS"
    Write-Host "      SQLite integrity evidence: PASS"
    Write-Host "      Expected request count: $($Manifest.request_count)"
    Write-Host "      Git commit: $($Manifest.git_commit)"

    if ($VerifyOnly) {
        Write-Host ""
        Write-Host "========================================"
        Write-Host "  4HRS BACKUP VERIFIED"
        Write-Host "========================================"
        Write-Host ""
        Write-Host "RECOVERY_MUTATION=NO"
        Write-Host "RESULT=PASS"
        return
    }

    #
    # Confirmation gate
    #
    if (-not $Force) {
        Write-Host ""
        Write-Host "WARNING:"
        Write-Host "Current procurement data may be replaced."
        Write-Host ""

        $Confirmation = Read-Host "Type RECOVER to continue"

        if ($Confirmation -ne "RECOVER") {
            throw "Recovery cancelled."
        }
    }

    #
    # Docker preflight
    #
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker CLI not found."
    }

    docker info *> $null

    if ($LASTEXITCODE -ne 0) {
        throw "Docker Engine is not available."
    }

    #
    # STEP 3 - Stop application
    #
    Write-Host ""
    Write-Host "[3/6] Stopping application..."

    docker compose down

    if ($LASTEXITCODE -ne 0) {
        throw "docker compose down failed."
    }

    Write-Host "      Application stopped: PASS"

    #
    # STEP 4 - Materialize volume and restore database
    #
    Write-Host ""
    Write-Host "[4/6] Restoring SQLite database..."

    docker compose create

    if ($LASTEXITCODE -ne 0) {
        throw "docker compose create failed."
    }

    $ContainerId = (
        docker compose ps -a -q procurement
    ).Trim()

    if (-not $ContainerId) {
        throw "Unable to resolve procurement container."
    }

    $InspectJson = docker inspect $ContainerId

    if ($LASTEXITCODE -ne 0) {
        throw "docker inspect failed."
    }

    $Inspect = $InspectJson | ConvertFrom-Json

    $DataMount = $Inspect[0].Mounts |
        Where-Object { $_.Destination -eq "/app/data" } |
        Select-Object -First 1

    if (-not $DataMount) {
        throw "Unable to resolve /app/data mount."
    }

    $VolumeName = $DataMount.Name

    if (-not $VolumeName) {
        throw "Unable to resolve procurement data volume."
    }

    $ImageName = (
        docker compose config --images |
            Select-Object -First 1
    ).Trim()

    if (-not $ImageName) {
        throw "Unable to resolve application image."
    }

    Write-Host "      Volume: $VolumeName"
    Write-Host "      Image:  $ImageName"

    $RestoreCode = @"
import hashlib
import shutil
import sqlite3
import sys

source = "/backup/procurement.db"
target = "/app/data/procurement.db"

shutil.copyfile(source, target)

with open(target, "rb") as f:
    restored_hash = hashlib.sha256(f.read()).hexdigest().upper()

conn = sqlite3.connect(target)

try:
    integrity = conn.execute(
        "PRAGMA integrity_check"
    ).fetchone()[0]
finally:
    conn.close()

print("RESTORED_SHA256=" + restored_hash)
print("SQLITE_INTEGRITY=" + integrity.upper())

expected_hash = "$ActualHash"

if restored_hash != expected_hash:
    print("HASH_VERIFICATION=FAIL")
    sys.exit(1)

if integrity != "ok":
    print("SQLITE_INTEGRITY=FAIL")
    sys.exit(1)

print("HASH_VERIFICATION=PASS")
print("RESTORE_DATABASE=PASS")
"@

    $RestoreCode | docker run --rm -i `
        --mount "type=volume,source=$VolumeName,target=/app/data" `
        --mount "type=bind,source=$BackupDir,target=/backup,readonly" `
        $ImageName `
        python -

    if ($LASTEXITCODE -ne 0) {
        throw "Database restore verification failed."
    }

    Write-Host "      Database restore: PASS"

    #
    # STEP 5 - Start application and wait for health
    #
    Write-Host ""
    Write-Host "[5/6] Starting recovered application..."

    docker compose up -d

    if ($LASTEXITCODE -ne 0) {
        throw "docker compose up failed."
    }

    $HealthUrl = "http://127.0.0.1:8000/healthz"
    $Healthy = $false
    $HealthResponse = $null

    for ($i = 1; $i -le 30; $i++) {
        try {
            $HealthResponse = Invoke-RestMethod `
                -Uri $HealthUrl `
                -Method Get `
                -TimeoutSec 3

            if ($HealthResponse.status -eq "ok") {
                $Healthy = $true
                break
            }
        }
        catch {
            # Application may still be starting.
        }

        Write-Host "      Waiting... ($i/30)"
        Start-Sleep -Seconds 2
    }

    if (-not $Healthy) {
        throw "Recovered application failed health check."
    }

    Write-Host "      Health check: PASS"
    Write-Host "      Version: $($HealthResponse.version)"

    #
    # STEP 6 - Business data validation
    #
    Write-Host ""
    Write-Host "[6/6] Validating recovered data..."

    $Requests = Invoke-RestMethod `
        -Uri "http://127.0.0.1:8000/requests" `
        -Method Get

    $ActualRequestCount = @($Requests).Count
    $ExpectedRequestCount = [int]$Manifest.request_count

    Write-Host "      Expected requests: $ExpectedRequestCount"
    Write-Host "      Actual requests:   $ActualRequestCount"

    if ($ExpectedRequestCount -ge 0) {
        if ($ActualRequestCount -ne $ExpectedRequestCount) {
            throw "Recovered request count does not match backup manifest."
        }
    }

    Write-Host "      Request validation: PASS"

    Write-Host ""
    docker compose ps

    Write-Host ""
    Write-Host "========================================"
    Write-Host "  4HRS RECOVERY COMPLETE"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Backup:"
    Write-Host $BackupDir
    Write-Host ""
    Write-Host "SHA256=$ActualHash"
    Write-Host "REQUEST_COUNT=$ActualRequestCount"
    Write-Host "HEALTH=PASS"
    Write-Host "RECOVERY=PASS"
    Write-Host "RESULT=PASS"
}
catch {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  4HRS RECOVERY FAILED"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "ERROR=$($_.Exception.Message)"
    Write-Host "RECOVERY=FAIL"
    Write-Host "RESULT=FAIL"

    exit 1
}
finally {
    Pop-Location
}


