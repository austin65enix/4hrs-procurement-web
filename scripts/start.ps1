$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================"
Write-Host "  4HRS Procurement - START"
Write-Host "========================================"
Write-Host ""

# Resolve project root from this script location
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

Push-Location $ProjectRoot

try {
    Write-Host "[1/4] Checking Docker..."

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker CLI not found."
    }

    docker info *> $null

    if ($LASTEXITCODE -ne 0) {
        throw "Docker Engine is not available."
    }

    Write-Host "      Docker: PASS"

    Write-Host ""
    Write-Host "[2/4] Building and starting application..."

    docker compose up -d --build

    if ($LASTEXITCODE -ne 0) {
        throw "docker compose up failed."
    }

    Write-Host "      Compose startup: PASS"

    Write-Host ""
    Write-Host "[3/4] Waiting for application health..."

    $HealthUrl = "http://127.0.0.1:8000/healthz"
    $Healthy = $false

    for ($i = 1; $i -le 30; $i++) {
        try {
            $Response = Invoke-RestMethod `
                -Uri $HealthUrl `
                -Method Get `
                -TimeoutSec 3

            if ($Response.status -eq "ok") {
                $Healthy = $true
                break
            }
        }
        catch {
            # Service may still be starting
        }

        Write-Host "      Waiting... ($i/30)"
        Start-Sleep -Seconds 2
    }

    if (-not $Healthy) {
        throw "Application health check failed after 60 seconds."
    }

    Write-Host "      Health check: PASS"
    Write-Host "      Version: $($Response.version)"

    Write-Host ""
    Write-Host "[4/4] Final status..."

    docker compose ps

    Write-Host ""
    Write-Host "========================================"
    Write-Host "  4HRS READY"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Application:"
    Write-Host "http://127.0.0.1:8000/"
    Write-Host ""
    Write-Host "API Docs:"
    Write-Host "http://127.0.0.1:8000/docs"
    Write-Host ""
    Write-Host "RESULT=PASS"
}
catch {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  4HRS START FAILED"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "ERROR=$($_.Exception.Message)"
    Write-Host "RESULT=FAIL"

    exit 1
}
finally {
    Pop-Location
}