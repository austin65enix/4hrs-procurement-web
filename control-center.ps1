Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$ErrorActionPreference = "SilentlyContinue"
$ProjectRoot = $PSScriptRoot
Set-Location $ProjectRoot

[xml]$Xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="4HRS Control Center"
    Width="760"
    Height="650"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    Background="#F3F4F6"
    FontFamily="Segoe UI">

    <Grid Margin="28">

        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="24"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="24"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="24"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0"
                Background="#18222E"
                CornerRadius="28"
                Padding="28">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel>
                    <TextBlock Text="4HRS Procurement"
                               Foreground="White"
                               FontSize="30"
                               FontWeight="SemiBold"/>
                    <TextBlock Text="Control Center"
                               Foreground="#B8C4D1"
                               FontSize="16"
                               Margin="0,6,0,0"/>
                </StackPanel>

                <StackPanel Grid.Column="1"
                            Orientation="Horizontal"
                            VerticalAlignment="Center">
                    <Ellipse x:Name="SystemDot"
                             Width="14"
                             Height="14"
                             Fill="#F59E0B"
                             Margin="0,0,10,0"/>
                    <TextBlock x:Name="SystemStatus"
                               Text="Checking..."
                               Foreground="White"
                               FontSize="16"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Status cards -->
        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="14"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="14"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <Border Grid.Column="0"
                    Background="White"
                    CornerRadius="22"
                    Padding="22">
                <StackPanel>
                    <TextBlock Text="Docker"
                               Foreground="#667085"
                               FontSize="14"/>
                    <TextBlock x:Name="DockerStatus"
                               Text="Checking..."
                               FontSize="22"
                               FontWeight="SemiBold"
                               Margin="0,8,0,0"/>
                </StackPanel>
            </Border>

            <Border Grid.Column="2"
                    Background="White"
                    CornerRadius="22"
                    Padding="22">
                <StackPanel>
                    <TextBlock Text="Application"
                               Foreground="#667085"
                               FontSize="14"/>
                    <TextBlock x:Name="AppStatus"
                               Text="Checking..."
                               FontSize="22"
                               FontWeight="SemiBold"
                               Margin="0,8,0,0"/>
                </StackPanel>
            </Border>

            <Border Grid.Column="4"
                    Background="White"
                    CornerRadius="22"
                    Padding="22">
                <StackPanel>
                    <TextBlock Text="Requests"
                               Foreground="#667085"
                               FontSize="14"/>
                    <TextBlock x:Name="RequestCount"
                               Text="-"
                               FontSize="22"
                               FontWeight="SemiBold"
                               Margin="0,8,0,0"/>
                </StackPanel>
            </Border>
        </Grid>

        <!-- Operations -->
        <Grid Grid.Row="4">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="16"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <Grid.RowDefinitions>
                <RowDefinition Height="92"/>
                <RowDefinition Height="16"/>
                <RowDefinition Height="92"/>
            </Grid.RowDefinitions>

            <Button x:Name="StartButton"
                    Grid.Row="0"
                    Grid.Column="0"
                    Content="▶   啟動系統"
                    FontSize="18"
                    FontWeight="SemiBold"
                    BorderThickness="0"
                    Background="White"
                    IsEnabled="False"/>

            <Button x:Name="VerifyButton"
                    Grid.Row="0"
                    Grid.Column="2"
                    Content="✓   系統檢查"
                    FontSize="18"
                    FontWeight="SemiBold"
                    BorderThickness="0"
                    Background="White"
                    IsEnabled="False"/>

            <Button x:Name="BackupButton"
                    Grid.Row="2"
                    Grid.Column="0"
                    Content="↑   建立備份"
                    FontSize="18"
                    FontWeight="SemiBold"
                    BorderThickness="0"
                    Background="White"
                    IsEnabled="False"/>

            <Button x:Name="RecoverButton"
                    Grid.Row="2"
                    Grid.Column="2"
                    Content="↻   災難復原"
                    FontSize="18"
                    FontWeight="SemiBold"
                    BorderThickness="0"
                    Background="White"
                    IsEnabled="False"/>
        </Grid>

        <!-- Bottom -->
        <Border Grid.Row="6"
                Background="White"
                CornerRadius="22"
                Padding="20">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="12"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel>
                    <TextBlock Text="Last Backup"
                               Foreground="#667085"
                               FontSize="13"/>
                    <TextBlock x:Name="BackupStatus"
                               Text="Checking..."
                               FontSize="16"
                               FontWeight="SemiBold"
                               Margin="0,4,0,0"/>
                </StackPanel>

                <Button x:Name="OpenWebButton"
                        Grid.Column="1"
                        Content="開啟網站"
                        Padding="22,10"
                        FontSize="14"/>

                <Button x:Name="RefreshButton"
                        Grid.Column="3"
                        Content="重新整理"
                        Padding="22,10"
                        FontSize="14"/>
            </Grid>
        </Border>

    </Grid>
</Window>
"@

$Reader = New-Object System.Xml.XmlNodeReader $Xaml
$Window = [Windows.Markup.XamlReader]::Load($Reader)

$SystemDot    = $Window.FindName("SystemDot")
$SystemStatus = $Window.FindName("SystemStatus")
$DockerStatus = $Window.FindName("DockerStatus")
$AppStatus    = $Window.FindName("AppStatus")
$RequestCount = $Window.FindName("RequestCount")
$BackupStatus = $Window.FindName("BackupStatus")
$OpenWebButton = $Window.FindName("OpenWebButton")
$RefreshButton = $Window.FindName("RefreshButton")
$VerifyButton  = $Window.FindName("VerifyButton")
$StartButton   = $Window.FindName("StartButton")
$BackupButton  = $Window.FindName("BackupButton")

# R12-B: VERIFY is the first mutation-capable GUI binding.
$VerifyButton.IsEnabled = $true
$StartButton.IsEnabled  = $true
$BackupButton.IsEnabled = $true

function Set-SystemState {
    param(
        [string]$Text,
        [string]$Color
    )

    $SystemStatus.Text = $Text
    $SystemDot.Fill = $Color
}

function Refresh-4HRSStatus {

    $DockerStatus.Text = "Stopped"
    $AppStatus.Text = "Offline"
    $RequestCount.Text = "-"
    $BackupStatus.Text = "None"

    Set-SystemState "Checking..." "#F59E0B"

    # Docker
    docker info *> $null

    if ($LASTEXITCODE -ne 0) {
        $DockerStatus.Text = "Unavailable"
        Set-SystemState "Attention" "#EF4444"
        return
    }

    $DockerStatus.Text = "Running"

    # Container
    $ContainerId = docker compose ps -q procurement |
        Select-Object -First 1

    if ([string]::IsNullOrWhiteSpace($ContainerId)) {
        $AppStatus.Text = "Stopped"
        Set-SystemState "Attention" "#F59E0B"
    }
    else {
        try {
            $Health = Invoke-RestMethod `
                -Uri "http://127.0.0.1:8000/healthz" `
                -TimeoutSec 3

            if ($Health.status -eq "ok") {
                $AppStatus.Text = "Healthy"

                $Requests = Invoke-RestMethod `
                    -Uri "http://127.0.0.1:8000/requests" `
                    -TimeoutSec 3

                $RequestCount.Text = @($Requests).Count.ToString()

                Set-SystemState "System Healthy" "#22C55E"
            }
            else {
                $AppStatus.Text = "Attention"
                Set-SystemState "Attention" "#F59E0B"
            }
        }
        catch {
            $AppStatus.Text = "Starting"
            Set-SystemState "Attention" "#F59E0B"
        }
    }

    # Latest backup
    $BackupRoot = Join-Path $ProjectRoot "backups"

    if (Test-Path $BackupRoot) {
        $Latest = Get-ChildItem $BackupRoot -Directory |
            Sort-Object Name -Descending |
            Select-Object -First 1

        if ($Latest) {
            $BackupStatus.Text = $Latest.Name
        }
    }
}

function Invoke-VerifyWheel {

    $VerifyButton.IsEnabled = $false
    $VerifyButton.Content = "⌛   系統檢查中..."

    Set-SystemState "Checking..." "#F59E0B"

    # Force WPF to repaint before running the child process.
    $Window.Dispatcher.Invoke(
        [Action]{},
        [Windows.Threading.DispatcherPriority]::Render
    )

    try {

        $VerifyScript = Join-Path $ProjectRoot "scripts\verify.ps1"

        if (-not (Test-Path $VerifyScript)) {
            throw "verify.ps1 not found."
        }

        $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo

        $ProcessInfo.FileName = "powershell.exe"
        $ProcessInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$VerifyScript`""
        $ProcessInfo.WorkingDirectory = $ProjectRoot
        $ProcessInfo.UseShellExecute = $false
        $ProcessInfo.CreateNoWindow = $true
        $ProcessInfo.RedirectStandardOutput = $true
        $ProcessInfo.RedirectStandardError = $true

        $Process = New-Object System.Diagnostics.Process
        $Process.StartInfo = $ProcessInfo

        [void]$Process.Start()

        $StdOut = $Process.StandardOutput.ReadToEnd()
        $StdErr = $Process.StandardError.ReadToEnd()

        $Process.WaitForExit()

        $ExitCode = $Process.ExitCode

        # Refresh GUI cards after wheel execution.
        Refresh-4HRSStatus

        if (($ExitCode -eq 0) -and ($StdOut -match "RESULT=PASS")) {

            [System.Windows.MessageBox]::Show(
                "系統檢查完成。`n`nDocker、Application、SQLite 與 API 均正常。",
                "4HRS Verify",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            ) | Out-Null
        }
        else {

            $CombinedOutput = $StdOut + "`n" + $StdErr

            $ErrorLine = $CombinedOutput -split "`r?`n" |
                Where-Object { $_ -match "^ERROR=" } |
                Select-Object -Last 1

            if (-not $ErrorLine) {
                $ErrorLine = "System verification failed."
            }

            [System.Windows.MessageBox]::Show(
                "系統檢查失敗。`n`n$ErrorLine",
                "4HRS Verify",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            ) | Out-Null
        }
    }
    catch {

        Refresh-4HRSStatus

        [System.Windows.MessageBox]::Show(
            "系統檢查無法執行。`n`n$($_.Exception.Message)",
            "4HRS Verify",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
    finally {

        $VerifyButton.Content = "✓   系統檢查"
        $VerifyButton.IsEnabled = $true
$StartButton.IsEnabled  = $true
$BackupButton.IsEnabled = $true
    }
}

$VerifyButton.Add_Click({
    Invoke-VerifyWheel
})
function Invoke-ControlCenterWheel {

    param(
        [string]$ScriptName,
        $Button,
        [string]$BusyText,
        [string]$IdleText,
        [string]$SuccessTitle,
        [string]$SuccessMessage
    )

    $Button.IsEnabled = $false
    $Button.Content = $BusyText

    Set-SystemState "Working..." "#F59E0B"

    $Window.Dispatcher.Invoke(
        [Action]{},
        [Windows.Threading.DispatcherPriority]::Render
    )

    try {

        $ScriptPath = Join-Path $ProjectRoot "scripts\$ScriptName"

        if (-not (Test-Path $ScriptPath)) {
            throw "$ScriptName not found."
        }

        $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessInfo.FileName = "powershell.exe"
        $ProcessInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
        $ProcessInfo.WorkingDirectory = $ProjectRoot
        $ProcessInfo.UseShellExecute = $false
        $ProcessInfo.CreateNoWindow = $true
        $ProcessInfo.RedirectStandardOutput = $true
        $ProcessInfo.RedirectStandardError = $true

        $Process = New-Object System.Diagnostics.Process
        $Process.StartInfo = $ProcessInfo

        [void]$Process.Start()

        $StdOut = $Process.StandardOutput.ReadToEnd()
        $StdErr = $Process.StandardError.ReadToEnd()

        $Process.WaitForExit()

        $ExitCode = $Process.ExitCode

        Refresh-4HRSStatus

        if (($ExitCode -eq 0) -and ($StdOut -match "RESULT=PASS")) {

            [System.Windows.MessageBox]::Show(
                $SuccessMessage,
                $SuccessTitle,
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            ) | Out-Null
        }
        else {

            $CombinedOutput = $StdOut + "`n" + $StdErr

            $ErrorLine = $CombinedOutput -split "`r?`n" |
                Where-Object { $_ -match "^ERROR=" } |
                Select-Object -Last 1

            if (-not $ErrorLine) {
                $ErrorLine = "$ScriptName failed."
            }

            [System.Windows.MessageBox]::Show(
                "操作失敗。`n`n$ErrorLine",
                "4HRS Control Center",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            ) | Out-Null
        }
    }
    catch {

        Refresh-4HRSStatus

        [System.Windows.MessageBox]::Show(
            "操作無法執行。`n`n$($_.Exception.Message)",
            "4HRS Control Center",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
    finally {

        $Button.Content = $IdleText
        $Button.IsEnabled = $true
    }
}

$StartButton.Add_Click({

    Invoke-ControlCenterWheel `
        -ScriptName "start.ps1" `
        -Button $StartButton `
        -BusyText "⌛   系統啟動中..." `
        -IdleText "▶   啟動系統" `
        -SuccessTitle "4HRS Start" `
        -SuccessMessage "系統啟動完成。`n`nApplication 已通過健康檢查。"
})

$BackupButton.Add_Click({

    Invoke-ControlCenterWheel `
        -ScriptName "backup.ps1" `
        -Button $BackupButton `
        -BusyText "⌛   備份建立中..." `
        -IdleText "↑   建立備份" `
        -SuccessTitle "4HRS Backup" `
        -SuccessMessage "備份建立完成。`n`nSQLite snapshot、Integrity 與 SHA256 均已完成。"
})
$RefreshButton.Add_Click({
    Refresh-4HRSStatus
})

$OpenWebButton.Add_Click({
    Start-Process "http://127.0.0.1:8000/"
})

$Window.Add_ContentRendered({
    Refresh-4HRSStatus
})

$Window.ShowDialog() | Out-Null


