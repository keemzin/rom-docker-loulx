#!/usr/bin/env python3
"""
install_patches.py
One-click installer to apply client OTA patches and server tables.

Usage:
    python scripts/install_patches.py
"""

import os
import shutil
import sys

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    patches_dir = os.path.join(root, "patches")
    res_dir = os.path.join(root, "web", "wwwroot", "127.0.0.1", "res")
    server_release_table = os.path.join(root, "server", "bin", "Release", "Lua", "Table")
    server_config_table = os.path.join(root, "server", "Config", "Lua", "Table")

    print("============================================================")
    print("    Ragnarok M - LouLx EP5 Patch Installer                  ")
    print("============================================================")

    # 1. Install Client OTA Patches
    if os.path.exists(res_dir):
        print(f"\n[*] 1/2: Installing client OTA patches -> {res_dir}")
        for f in os.listdir(patches_dir):
            if f.endswith(".zip") or f == "patch.meta.json":
                src = os.path.join(patches_dir, f)
                dst = os.path.join(res_dir, f)
                shutil.copy2(src, dst)
                print(f"  [+] Copied {f} ({os.path.getsize(dst):,} bytes)")
    else:
        print(f"\n[!] Notice: {res_dir} not found yet. Extract wwwroot.zip first.")

    # 2. Install Server Tables (Pet AI, Skills, Normalized Attack Speed)
    server_tables_dir = os.path.join(patches_dir, "server_tables")
    if os.path.exists(server_tables_dir):
        print(f"\n[*] 2/2: Installing server tables (Pet AI, Skills, Attack Speeds)...")
        release_src = os.path.join(server_tables_dir, "Release")
        config_src = os.path.join(server_tables_dir, "Config")

        if os.path.exists(server_release_table) and os.path.exists(release_src):
            for f in os.listdir(release_src):
                src = os.path.join(release_src, f)
                dst = os.path.join(server_release_table, f)
                shutil.copy2(src, dst)
                print(f"  [+] Release Table: {f} ({os.path.getsize(dst):,} bytes)")

        if os.path.exists(server_config_table) and os.path.exists(config_src):
            for f in os.listdir(config_src):
                src = os.path.join(config_src, f)
                dst = os.path.join(server_config_table, f)
                shutil.copy2(src, dst)
                print(f"  [+] Config Table:  {f} ({os.path.getsize(dst):,} bytes)")
    
    print("\n[✔] All patches installed successfully!")
    print("    If the game server is already running, run: docker restart rom-game-lolx\n")

if __name__ == "__main__":
    main()
