@echo off
REM ============================================================
REM One-Click Asset Downloader & Extractor for Ragnarok M
REM ============================================================
cd /d "%~dp0\.."

where python >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python 3 was not found in PATH.
    echo Please install Python 3 or download assets manually from Hugging Face:
    echo https://huggingface.co/datasets/johnsdoes/docker-rom/tree/main/loulx
    pause
    exit /b 1
)

python scripts\download_assets.py %*
pause
