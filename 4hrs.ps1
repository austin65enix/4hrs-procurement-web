$ErrorActionPreference = "Continue"

$ProjectRoot = $PSScriptRoot
Set-Location $ProjectRoot

function Pause-4HRS {
    Write-Host ""
    Read-Host "按 Enter 返回主選單"
}

while ($true) {

    Clear-Host

    Write-Host "========================================"
    Write-Host "        4HRS Procurement"
    Write-Host "========================================"
    Write-Host ""
    Write-Host " [1] 啟動系統"
    Write-Host " [2] 系統檢查"
    Write-Host " [3] 建立備份"
    Write-Host " [4] 災難復原"
    Write-Host " [5] 開啟網站"
    Write-Host " [6] 停止系統"
    Write-Host ""
    Write-Host " [0] 離開"
    Write-Host ""

    $Choice = Read-Host "請選擇"

    switch ($Choice) {

        "1" {
            Clear-Host
            & "$ProjectRoot\scripts\start.ps1"

            if ($LASTEXITCODE -eq 0) {
                Start-Process "http://127.0.0.1:8000/"
            }

            Pause-4HRS
        }

        "2" {
            Clear-Host
            & "$ProjectRoot\scripts\verify.ps1"
            Pause-4HRS
        }

        "3" {
            Clear-Host
            & "$ProjectRoot\scripts\backup.ps1"
            Pause-4HRS
        }

        "4" {
            Clear-Host
            Write-Host "========================================"
            Write-Host "       4HRS 災難復原"
            Write-Host "========================================"
            Write-Host ""
            Write-Host "系統將先驗證備份，再要求 RECOVER 確認。"
            Write-Host ""

            & "$ProjectRoot\scripts\recover.ps1"

            Pause-4HRS
        }

        "5" {
            Start-Process "http://127.0.0.1:8000/"
        }

        "6" {
            Clear-Host
            Write-Host "Stopping 4HRS Procurement..."
            Write-Host ""

            docker compose down

            Write-Host ""
            Write-Host "資料 Volume 保留，不會刪除。"
            Write-Host "RESULT=PASS"

            Pause-4HRS
        }

        "0" {
            break
        }

        default {
            Write-Host ""
            Write-Host "無效選項。"
            Start-Sleep -Seconds 1
        }
    }

    if ($Choice -eq "0") {
        break
    }
}
