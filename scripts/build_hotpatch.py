#!/usr/bin/env python3
"""
Ragnarok M (LouLx EP5) - Automated Client Hotpatch Builder
==========================================================
Extracts base asset bundles from the APK, encrypts Lua scripts with LouLx's
AES-256-CBC cipher, injects them into Unity TextAssets, packages patch.zip/patch1.zip,
and updates patch.meta.json with version bumping and MD5 checksums.

Usage:
    python scripts/build_hotpatch.py
"""

import os
import sys
import io
import json
import base64
import struct
import hashlib
import zipfile
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad
import UnityPy

# LouLx EP5 AES-256-CBC Key & IV
AES_KEY = base64.b64decode("Cu+obWg1Ktl42Rjn+5xQvDRX1j1o+dxswxKtTc4UiFs=")
AES_IV = base64.b64decode("22s411Xw+uyJir2ye0gyig==")

def enc_aes(text: str) -> bytes:
    """Encrypts plaintext Lua source with AES-256-CBC + PKCS#7 padding."""
    raw = text.encode("utf-8")
    return AES.new(AES_KEY, AES.MODE_CBC, AES_IV).encrypt(pad(raw, 16))

def dec_aes(enc_bytes: bytes) -> str:
    """Decrypts AES-256-CBC ciphertext into UTF-8 string."""
    dec = AES.new(AES_KEY, AES.MODE_CBC, AES_IV).decrypt(enc_bytes)
    return unpad(dec, 16).decode("utf-8")

def find_root_dir() -> str:
    """Determines repo root based on script location."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.dirname(script_dir)

def find_apk(root_dir: str) -> str:
    """Locates the master 2.1GB LouLx APK."""
    env_apk = os.environ.get("RO_APK_PATH")
    if env_apk and os.path.exists(env_apk):
        return env_apk

    candidates = [
        os.path.join(root_dir, "client", "loulx-rom.apk"),
        os.path.join(root_dir, "client", "lolsx_rom_original.apk"),
        os.path.join(root_dir, "client", "ROM.apk"),
        os.path.join(root_dir, "client", "rom.apk"),
        os.path.join(root_dir, "ROM.apk"),
        os.path.join(os.path.dirname(root_dir), "ROM-LouLx", "ROM.apk"),
    ]
    for c in candidates:
        if os.path.exists(c) and os.path.getsize(c) > 1_500_000_000:
            return c
    raise FileNotFoundError(f"LouLx base APK not found! Place ROM.apk in client/ or set RO_APK_PATH. Checked: {candidates}")

def patch_bundle(bundle_bytes: bytes, script_names: list, patched_lua_dir: str) -> bytes:
    """
    Injects patched Lua scripts into a Unity AssetBundle (.unity3d).
    Reconstructs the binary TextAsset header (name length, aligned name, data length, ciphertext).
    """
    env = UnityPy.load(bundle_bytes)
    patched_count = 0
    for obj in env.objects:
        if obj.type.name == "TextAsset":
            d = obj.read()
            if d.m_Name in script_names:
                lua_path = os.path.join(patched_lua_dir, f"{d.m_Name}.lua")
                if os.path.exists(lua_path):
                    with open(lua_path, "r", encoding="utf-8") as f:
                        text = f.read()
                    enc_data = enc_aes(text)
                    nl = len(d.m_Name.encode("utf-8"))
                    pad_len = ((4 + nl + 3) & ~3) - (4 + nl)
                    new_raw = (
                        struct.pack("<I", nl)
                        + d.m_Name.encode("utf-8")
                        + (b"\x00" * pad_len)
                        + struct.pack("<I", len(enc_data))
                        + enc_data
                    )
                    obj.set_raw_data(new_raw)
                    patched_count += 1
                    print(f"  [+] Patched TextAsset: {d.m_Name} ({len(enc_data):,} bytes)")
    return env.file.save(packer="lz4")

def update_patch_metadata(res_dir: str, patch_files: list, patch_bytes: bytes) -> dict:
    """Calculates MD5, file size, bumps version number, and updates patch.meta.json."""
    meta_path = os.path.join(res_dir, "patch.meta.json")
    meta = {"files": {}}
    if os.path.exists(meta_path):
        try:
            with open(meta_path, "r", encoding="utf-8") as f:
                meta = json.load(f)
        except Exception:
            pass

    files_meta = meta.get("files", {})
    if not isinstance(files_meta, dict):
        files_meta = {}
        meta["files"] = files_meta

    max_ver = 400080
    for finfo in files_meta.values():
        if isinstance(finfo, dict) and finfo.get("version", 0) > max_ver:
            max_ver = finfo["version"]

    md5_hash = hashlib.md5(patch_bytes).hexdigest()
    file_size = len(patch_bytes)

    for fname in patch_files:
        cur_ver = max_ver + 1
        max_ver = cur_ver
        meta.setdefault("files", {})[fname] = {
            "version": cur_ver,
            "md5": md5_hash,
            "size": file_size,
            "mtime": int(os.path.getmtime(os.path.join(res_dir, fname))) if os.path.exists(os.path.join(res_dir, fname)) else 1794546815
        }

    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=4)
    return meta

def main():
    root = find_root_dir()
    lua_dir = os.path.join(root, "client", "patch_lua")
    apk_path = find_apk(root)
    res_dir = os.path.join(root, "web", "wwwroot", "127.0.0.1", "res")

    # Determine which patch archives to generate (default: patch2.zip)
    if len(sys.argv) > 1:
        arg = sys.argv[1].strip()
        if not arg.endswith(".zip"):
            arg += ".zip"
        target_patches = [arg]
    else:
        target_patches = ["patch2.zip"]

    print("============================================================")
    print("    Ragnarok M - LouLx EP5 OTA Hotpatch Builder             ")
    print("============================================================")
    print(f"[*] Repository Root: {root}")
    print(f"[*] Base APK:        {apk_path} ({os.path.getsize(apk_path):,} bytes)")
    print(f"[*] Patched Lua Dir: {lua_dir}")
    print(f"[*] Target Res Dir:  {res_dir}")
    print(f"[*] Target Patches:  {target_patches}")

    framework_scripts = [
        "MainViewMenuPage", "MainViewMiniMap", "MainViewTaskQuestPage",
        "QuestTraceCell", "SceneProxy", "ServiceUserEventProxy",
        "UIListItemCtrlLuckyBag", "UIListItemViewControllerZenyShopItem",
        "UISubViewControllerGachaCoin", "UISubViewControllerMonthlyVIP",
        "UISubViewControllerZenyList", "UIViewControllerZenyShop",
        "HappyShopProxy", "LotteryView", "MainViewHeadPage",
        "UniqueConfirmView"
    ]

    with zipfile.ZipFile(apk_path, "r") as apk_z:
        # 1. framework.unity3d in assets4.zip
        print("\n[*] 1/1: Patching framework.unity3d (Quest Teleport, Auto-Complete, Shop, Free BCC, Boss UI, Pet Head UI)...")
        z4 = zipfile.ZipFile(io.BytesIO(apk_z.read("assets/assets4.zip")))
        fw_bytes = patch_bundle(z4.read("Android/resources/script2/framework.unity3d"), framework_scripts, lua_dir)

        pay_bytes = None
        func_bytes = None
        pet_cfg_bytes = None
        com_bytes = None
        refactory_bytes = None
        skill_cfg_bytes = None

        build_all = "--all" in sys.argv or "patch.zip" in target_patches or "patch1.zip" in target_patches or "patch3.zip" in target_patches
        if build_all:
            print("\n[*] 2/7: Patching config_pay_zhifu.unity3d (Table_MonthCard 2026 fix)...")
            z10 = zipfile.ZipFile(io.BytesIO(apk_z.read("assets/assets10.zip")))
            pay_bytes = patch_bundle(z10.read("Android/resources/script2/config_pay_zhifu.unity3d"), ["Table_MonthCard"], lua_dir)

            print("\n[*] 3/7: Patching functionsystem.unity3d (FunctionMonster)...")
            z9 = zipfile.ZipFile(io.BytesIO(apk_z.read("assets/assets9.zip")))
            func_bytes = patch_bundle(z9.read("Android/resources/script2/functionsystem.unity3d"), ["FunctionMonster"], lua_dir)

            print("\n[*] 4/7: Patching config_pet_suicong.unity3d (Table_Pet, Table_Pet_FriendLevel)...")
            z6 = zipfile.ZipFile(io.BytesIO(apk_z.read("assets/assets6.zip")))
            pet_cfg_bytes = patch_bundle(z6.read("Android/resources/script2/config_pet_suicong.unity3d"), ["Table_Pet", "Table_Pet_FriendLevel"], lua_dir)

            print("\n[*] 5/7: Patching com.unity3d (PetInfoData nil guard)...")
            z14 = zipfile.ZipFile(io.BytesIO(apk_z.read("assets/assets14.zip")))
            com_bytes = patch_bundle(z14.read("Android/resources/script2/com.unity3d"), ["PetInfoData"], lua_dir)

            print("\n[*] 6/7: Patching refactory.unity3d (PetData, NPet, Game_Interface_ForCSharp)...")
            z11 = zipfile.ZipFile(io.BytesIO(apk_z.read("assets/assets11.zip")))
            refactory_bytes = patch_bundle(z11.read("Android/resources/script2/refactory.unity3d"), ["PetData", "NPet", "Game_Interface_ForCSharp"], lua_dir)

            print("\n[*] 7/7: Patching config_skill_jineng.unity3d (Table_Skill fixes)...")
            z27 = zipfile.ZipFile(io.BytesIO(apk_z.read("assets/assets27.zip")))
            skill_cfg_bytes = patch_bundle(z27.read("Android/resources/script2/config_skill_jineng.unity3d"), ["Table_Skill"], lua_dir)

    # 7. Construct hotpatch zip archives
    print(f"\n[*] Building in-memory {', '.join(target_patches)} archive...")
    zip_buf = io.BytesIO()
    with zipfile.ZipFile(zip_buf, "w", zipfile.ZIP_DEFLATED) as out_z:
        out_z.writestr("Android/resources/script2/framework.unity3d", fw_bytes)
        if pay_bytes:
            out_z.writestr("Android/resources/script2/config_pay_zhifu.unity3d", pay_bytes)
        if func_bytes:
            out_z.writestr("Android/resources/script2/functionsystem.unity3d", func_bytes)
        if pet_cfg_bytes:
            out_z.writestr("Android/resources/script2/config_pet_suicong.unity3d", pet_cfg_bytes)
        if com_bytes:
            out_z.writestr("Android/resources/script2/com.unity3d", com_bytes)
        if refactory_bytes:
            out_z.writestr("Android/resources/script2/refactory.unity3d", refactory_bytes)
        if skill_cfg_bytes:
            out_z.writestr("Android/resources/script2/config_skill_jineng.unity3d", skill_cfg_bytes)
    final_zip_bytes = zip_buf.getvalue()

    os.makedirs(res_dir, exist_ok=True)
    for p_name in target_patches:
        target_path = os.path.join(res_dir, p_name)
        with open(target_path, "wb") as f:
            f.write(final_zip_bytes)
        print(f"[+] Wrote {target_path} ({len(final_zip_bytes):,} bytes)")

    # 8. Update patch.meta.json
    meta = update_patch_metadata(res_dir, target_patches, final_zip_bytes)
    print("\n[+] Updated patch.meta.json:")
    print(json.dumps(meta, indent=2))
    print("\n[+] Build successfully completed! Clients will download this OTA patch on next game launch.")

if __name__ == "__main__":
    main()
