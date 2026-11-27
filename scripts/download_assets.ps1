# ============================================================
# One-Click Asset Downloader & Extractor for Ragnarok M
# ============================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Python 3 was not found in PATH." -ForegroundColor Red
    Write-Host "Please install Python 3 or download assets manually from Hugging Face:" -ForegroundColor Yellow
    Write-Host "https://huggingface.co/datasets/johnsdoes/docker-rom/tree/main/loulx" -ForegroundColor Cyan
    exit 1
}

python scripts\download_assets.py @args
