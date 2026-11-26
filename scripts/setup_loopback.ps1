<#
.SYNOPSIS
    Automated setup script for Microsoft KM-TEST Loopback Adapter (192.168.128.129).
.DESCRIPTION
    Configures a native Windows loopback network adapter for Ragnarok M Docker stack,
    eliminating the requirement for VMware Workstation / VMnet8.
#>

# Ensure script is running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "This script requires Administrator privileges to configure network adapters."
    Write-Host "Relaunching in an elevated PowerShell prompt..." -ForegroundColor Cyan
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    exit
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  Ragnarok M - Microsoft Loopback Adapter Auto-Config    " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""

$targetIP = "192.168.128.129"
$targetPrefix = 24

# 1. Check for IP conflicts on other adapters (e.g., VMnet8)
$conflictingAdapters = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {
    $_.IPAddress -eq $targetIP -and $_.InterfaceAlias -notlike "*Loopback*"
}

if ($conflictingAdapters) {
    foreach ($conflict in $conflictingAdapters) {
        $adapter = Get-NetAdapter -Name $conflict.InterfaceAlias -ErrorAction SilentlyContinue
        if ($adapter -and $adapter.Status -ne "Disabled") {
            Write-Warning "Detected conflicting adapter '$($adapter.Name)' already holding $targetIP!"
            $choice = Read-Host "Disable '$($adapter.Name)' to prevent network conflicts? (Y/n)"
            if ($choice -ne 'n' -and $choice -ne 'N') {
                Disable-NetAdapter -Name $adapter.Name -Confirm:$false
                Write-Host "Disabled '$($adapter.Name)'." -ForegroundColor Yellow
            }
        }
    }
}

# 2. Locate Microsoft KM-TEST Loopback Adapter
$loopback = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
    $_.InterfaceDescription -like "*KM-TEST Loopback*" -or $_.Name -like "*RO-Loopback*" -or $_.Name -like "*Loopback*"
} | Select-Object -First 1

if (-not $loopback) {
    Write-Warning "Microsoft KM-TEST Loopback Adapter was not detected on this system."
    Write-Host ""
    Write-Host "Please install it manually via the Hardware Wizard (takes 30 seconds):" -ForegroundColor Cyan
    Write-Host "  1. Opening 'hdwwiz.exe' for you now..." -ForegroundColor Yellow
    Write-Host "  2. Choose 'Install the hardware that I manually select from a list (Advanced)' -> Next" -ForegroundColor Yellow
    Write-Host "  3. Select 'Network adapters' -> Next" -ForegroundColor Yellow
    Write-Host "  4. Manufacturer: 'Microsoft' -> Model: 'Microsoft KM-TEST Loopback Adapter' -> Next -> Finish" -ForegroundColor Yellow
    Write-Host ""
    Start-Process "hdwwiz.exe"
    Read-Host "Press Enter once the adapter installation has finished"
    
    $loopback = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
        $_.InterfaceDescription -like "*KM-TEST Loopback*"
    } | Select-Object -First 1
}

if (-not $loopback) {
    Write-Error "Could not find Microsoft KM-TEST Loopback Adapter. Please run this script again after installation."
    exit 1
}

# 3. Rename adapter for clarity (if still using generic default name like 'Ethernet 2')
if ($loopback.Name -like "Ethernet*" -and $loopback.Name -ne "RO-Loopback") {
    try {
        Rename-NetAdapter -Name $loopback.Name -NewName "RO-Loopback" -ErrorAction Stop
        $loopback = Get-NetAdapter -Name "RO-Loopback"
        Write-Host "[OK] Renamed adapter to 'RO-Loopback'." -ForegroundColor Green
    } catch {
        # Ignore if rename fails (permissions or in use)
    }
}

# 4. Configure IPv4 Address
$currentIP = Get-NetIPAddress -InterfaceIndex $loopback.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {
    $_.IPAddress -eq $targetIP
}

if ($currentIP) {
    Write-Host "[OK] Adapter '$($loopback.Name)' already has IP $targetIP configured." -ForegroundColor Green
} else {
    Write-Host "Assigning IP $targetIP ($targetPrefix-bit / 255.255.255.0) to '$($loopback.Name)'..." -ForegroundColor Cyan
    # Remove existing static or auto-assigned IPv4 on this adapter
    Get-NetIPAddress -InterfaceIndex $loopback.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false
    New-NetIPAddress -InterfaceIndex $loopback.ifIndex -IPAddress $targetIP -PrefixLength $targetPrefix | Out-Null
    Write-Host "[OK] IP $targetIP assigned successfully." -ForegroundColor Green
}

# 5. Verify connectivity
Write-Host ""
Write-Host "Testing web dashboard at http://${targetIP}:81..." -ForegroundColor Cyan
try {
    $res = Invoke-WebRequest -Uri "http://${targetIP}:81" -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
    if ($res.StatusCode -eq 200) {
        Write-Host "[SUCCESS] Docker Web Portal responded with HTTP 200 OK!" -ForegroundColor Green
    }
} catch {
    Write-Host "[NOTE] Server did not respond on port 81 yet. Make sure Docker is running: 'docker compose up -d'" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Setup Complete! You can now launch ROM.apk client." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
