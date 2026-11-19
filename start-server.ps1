Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "    Ragnarok M Server Stack - Startup & Health Check        " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$driveLetter = (Get-Location).Drive.Name
if (-not $driveLetter) { $driveLetter = "G" }

# 1. Check & Mount Drive into Docker Desktop WSL VM
Write-Host "[*] Checking if drive ${driveLetter}: is mounted in Docker Desktop WSL..." -ForegroundColor Yellow
$mounted = $false
try {
    $check = wsl -d docker-desktop -u root -e mount 2>$null | Select-String -Pattern "mnt/host/$($driveLetter.ToLower())"
    if ($check) { $mounted = $true }
} catch {
    $mounted = $false
}

if (-not $mounted) {
    Write-Host "[!] Drive ${driveLetter}: is not mounted in WSL. Mounting now..." -ForegroundColor Yellow
    wsl -d docker-desktop -u root -e mkdir -p "/mnt/host/$($driveLetter.ToLower())" 2>$null
    wsl -d docker-desktop -u root -e mount -t drvfs "${driveLetter}:" "/mnt/host/$($driveLetter.ToLower())" 2>$null
    Write-Host "[+] Drive ${driveLetter}: successfully mounted in WSL." -ForegroundColor Green
} else {
    Write-Host "[+] Drive ${driveLetter}: is already mounted in WSL." -ForegroundColor Green
}

# 2. Start Docker Compose Stack
Write-Host "[*] Starting Docker Compose stack..." -ForegroundColor Cyan
docker compose up -d

Write-Host "[+] All containers started. Checking status in 5s..." -ForegroundColor Green
Start-Sleep -Seconds 5
docker compose ps
