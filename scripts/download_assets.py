#!/usr/bin/env python3
"""
download_assets.py
Automated asset downloader and extractor for Ragnarok M (LouLx EP5).

Downloads pre-configured server and client assets from Hugging Face:
  - server.zip   -> ./server/
  - wwwroot.zip  -> ./web/wwwroot/
  - init.zip     -> ./db/init/
  - ROM.apk      -> ./ROM.apk

Usage:
  python scripts/download_assets.py
  python scripts/download_assets.py --no-apk   (skip 2GB APK download)
  python scripts/download_assets.py --force    (overwrite existing directories)
"""

import os
import sys
import time
import zipfile
import shutil
import urllib.request
import argparse

HF_BASE_URL = "https://huggingface.co/datasets/johnsdoes/docker-rom/resolve/main/loulx"

ASSETS = [
    {
        "name": "Server Binaries & Configs",
        "file": "server.zip",
        "target_dir": "server",
        "check_file": os.path.join("server", "bin", "Release", "SuperServer"),
        "extract": True,
    },
    {
        "name": "Web Portal & GM Tools",
        "file": "wwwroot.zip",
        "target_dir": os.path.join("web", "wwwroot"),
        "check_file": os.path.join("web", "wwwroot", "127.0.0.1", "version.php"),
        "extract": True,
    },
    {
        "name": "Database Initial SQL Dumps",
        "file": "init.zip",
        "target_dir": os.path.join("db", "init"),
        "check_file": os.path.join("db", "init", "ro_global.sql"),
        "extract": True,
    },
    {
        "name": "64-Bit Android Client (ROM.apk)",
        "file": "ROM.apk",
        "target_dir": ".",
        "check_file": "ROM.apk",
        "extract": False,
        "is_apk": True,
    },
]

def format_size(bytes_num):
    for unit in ['B', 'KB', 'MB', 'GB']:
        if bytes_num < 1024.0:
            return f"{bytes_num:.1f} {unit}"
        bytes_num /= 1024.0
    return f"{bytes_num:.1f} TB"

def download_file(url, dest_path):
    print(f"\n[*] Connecting to: {url}")
    start_time = time.time()
    
    # Custom opener with User-Agent to avoid HF generic bot blocks
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "rom-docker-loulx-installer/1.0"}
    )
    
    with urllib.request.urlopen(req) as response, open(dest_path, 'wb') as out_file:
        total_size = int(response.info().get('Content-Length', 0))
        downloaded = 0
        chunk_size = 1024 * 512  # 512 KB chunks
        last_update = time.time()
        
        while True:
            chunk = response.read(chunk_size)
            if not chunk:
                break
            out_file.write(chunk)
            downloaded += len(chunk)
            
            now = time.time()
            if now - last_update > 0.25 or downloaded == total_size:
                elapsed = now - start_time
                speed = downloaded / elapsed if elapsed > 0 else 0
                pct = (downloaded / total_size * 100) if total_size > 0 else 0
                bar_len = 30
                filled = int(bar_len * pct / 100)
                bar = '=' * filled + '-' * (bar_len - filled)
                status = f"\r  [{bar}] {pct:5.1f}% | {format_size(downloaded)}/{format_size(total_size)} | {format_size(speed)}/s"
                sys.stdout.write(status)
                sys.stdout.flush()
                last_update = now

    print(f"\n  [+] Download complete: {os.path.basename(dest_path)} ({format_size(downloaded)}) in {time.time()-start_time:.1f}s")

def extract_archive(archive_path, target_dir):
    print(f"[*] Extracting {os.path.basename(archive_path)} into ./{target_dir}/...")
    os.makedirs(target_dir, exist_ok=True)
    
    with zipfile.ZipFile(archive_path, 'r') as zip_ref:
        # Detect if zip has redundant top-level directory matching target_dir
        infolist = zip_ref.infolist()
        first_dir = infolist[0].filename.split('/')[0] if infolist else ""
        has_redundant_dir = False
        
        target_basename = os.path.basename(os.path.normpath(target_dir))
        if first_dir and first_dir.lower() == target_basename.lower():
            # Archive already contains 'server/...' or 'init/...'
            # Extract to target's parent to avoid server/server/
            extract_dest = os.path.dirname(os.path.normpath(target_dir)) or "."
            has_redundant_dir = True
        else:
            extract_dest = target_dir

        total_files = len(infolist)
        for idx, member in enumerate(infolist):
            zip_ref.extract(member, extract_dest)
            if (idx + 1) % 100 == 0 or idx + 1 == total_files:
                pct = ((idx + 1) / total_files) * 100
                sys.stdout.write(f"\r  Extracted {idx+1}/{total_files} files ({pct:.0f}%)...")
                sys.stdout.flush()

    print(f"\n  [+] Successfully extracted to {target_dir}")

def main():
    parser = argparse.ArgumentParser(description="Download and extract LouLx EP5 server & client assets.")
    parser.add_argument("--no-apk", action="store_true", help="Skip downloading the 2GB ROM.apk client.")
    parser.add_argument("--force", action="store_true", help="Overwrite existing files without prompting.")
    parser.add_argument("--keep-zips", action="store_true", help="Keep downloaded .zip files after extraction.")
    args = parser.parse_args()

    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(root_dir)

    print("============================================================")
    print("    Ragnarok M: LouLx EP5 - Automated Asset Setup           ")
    print("============================================================")
    print(f"Target Project Directory: {root_dir}")
    print(f"Source Repository:        {HF_BASE_URL}\n")

    for asset in ASSETS:
        if asset.get("is_apk") and args.no_apk:
            print(f"[!] Skipping {asset['name']} (--no-apk specified)")
            continue

        target_path = os.path.join(root_dir, asset["target_dir"])
        check_path = os.path.join(root_dir, asset["check_file"])

        if os.path.exists(check_path) and not args.force:
            print(f"[+] Found existing {asset['name']} ({asset['check_file']}). Skipping download.")
            continue

        download_url = f"{HF_BASE_URL}/{asset['file']}"
        local_archive = os.path.join(root_dir, asset["file"])

        # 1. Download
        try:
            download_file(download_url, local_archive)
        except Exception as e:
            print(f"\n[!] Error downloading {asset['file']}: {e}")
            print(f"    You can download manually from: {download_url}")
            continue

        # 2. Extract (if zip)
        if asset["extract"]:
            try:
                extract_archive(local_archive, target_path)
            except Exception as e:
                print(f"\n[!] Error extracting {asset['file']}: {e}")
                continue

            # 3. Clean up zip
            if not args.keep_zips and os.path.exists(local_archive):
                try:
                    os.remove(local_archive)
                    print(f"  [-] Cleaned up temporary {asset['file']}")
                except Exception:
                    pass

    # 4. Automatically install latest patches & server tables
    install_script = os.path.join(root_dir, "scripts", "install_patches.py")
    if os.path.exists(install_script):
        print("\n[*] Applying latest client OTA patches and server tables...")
        os.system(f'"{sys.executable}" "{install_script}"')

    print("\n============================================================")
    print("    🎉 Setup Complete!                                      ")
    print("============================================================")
    print("Next Steps:")
    print("  1. Ensure Loopback Adapter (192.168.128.129) is enabled:")
    print("     powershell -ExecutionPolicy Bypass -File scripts\\setup_loopback.ps1")
    print("  2. Start Docker Containers:")
    print("     docker compose up -d")
    print("  3. Wait ~2 minutes for '[SceneServer1],Server is Ready', then play!")
    print("============================================================\n")

if __name__ == "__main__":
    main()
