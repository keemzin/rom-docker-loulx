with open('TROUBLESHOOTING.md', 'r', encoding='utf-8') as f:
    content = f.read()

old_toc = '8. [Client APK Modding & Gateway Pointers](#8-client-apk-modding--gateway-pointers)'
new_toc = '8. [Client APK Architecture, Decompilation, Asset Extraction & OTA Hot-Patching Guide](#8-client-apk-architecture-decompilation-asset-extraction--ota-hot-patching-guide)'

assert old_toc in content, 'TOC string not found'
content = content.replace(old_toc, new_toc)

old_sec = """## 8. Client APK Modding & Gateway Pointers

If modifying or repacking the mobile client APK:
1. **Server Host IP:** The server IP configured for this stack is `192.168.1.234`.
2. **Gateway Endpoints in Client:**
   - Web Login / Register API: `http://192.168.1.234:81/`
   - Patch / CDN Server: `http://192.168.1.234:80/patch/`
   - Initial Proxy Gateway Port: `14288`
   - Gate Ports: `7080`, `7081`, `7082`
3. **Unity Binary Locations:**
   - For Mono Unity APKs: `assets/bin/Data/Managed/Assembly-CSharp.dll`
   - For IL2CPP Unity APKs: `lib/armeabi-v7a/libil2cpp.so` + `assets/bin/Data/Managed/Metadata/global-metadata.dat`
4. **Important:** Do not edit client files without explicit user confirmation."""

new_sec = """## 8. Client APK Architecture, Decompilation, Asset Extraction & OTA Hot-Patching Guide

> [!IMPORTANT]
> **Authoritative Reference Guide for AI Agents & Developers**:
> This section explains how to inspect, unpack, modify, and build Over-The-Air (OTA) patches for the Ragnarok M client APK.
> **Golden Rule**: Always prefer creating incremental OTA patches (`patch3.zip`) rather than modifying or rebuilding the full 2 GB APK.

---

### 8.1 APK Internal Structure & Asset Layout
An Android APK is a standard ZIP archive. Ragnarok M packages its game assets into sub-archives to optimize Android filesystem performance:
- **`assets/assets*.zip`**: Sub-archives holding Unity AssetBundles.
  - In `ROM.apk` (2.1 GB LouLx client):
    - `assets/assets4.zip` -> `Android/resources/script2/framework.unity3d` (Core Lua scripts & views, ~9.2 MB).
    - `assets/assets27.zip` -> `Android/resources/script2/framework.unity3d.manifest`.
  - In `quick_jump_rom.apk` (1.5 GB client):
    - `assets/assets32.zip` -> `Android/resources/script2/framework.unity3d` (Core Lua scripts, ~8.6 MB).
- **Unity AssetBundle (`framework.unity3d`)**:
  Contains 1,300+ compiled `TextAsset` objects holding UI logic (`MainViewTaskQuestPage`, `ShopMallExchangeView`, `QuestTraceCell`), network proxies (`ServiceRecordTradeProxy`, `ServiceGMProxy`), and controllers.

---

### 8.2 Lua Encryption & Decryption Standard
All client Lua scripts packed inside `framework.unity3d` (and `.bytes` files under `script2/`) are encrypted:
1. **Cipher**: DES in ECB mode.
2. **Key**: `bytes([64, 160, 144, 192, 96, 128, 0, 128])` (Hex: `40 A0 90 C0 60 80 00 80`).
3. **Header**: 8-byte magic string `czjzgqde` followed by a 4-byte unsigned integer (little-endian `<I`) indicating the unencrypted byte length.
4. **Padding**: Padded with `0x01` bytes to 8-byte block boundaries.

#### Python Decryption & Encryption Helper:
```python
from Crypto.Cipher import DES
import struct

DES_KEY = bytes([64, 160, 144, 192, 96, 128, 0, 128])
MAGIC_HEADER = b'czjzgqde'

def decrypt_lua(raw_data: bytes) -> bytes:
    \"\"\"Decrypts a client Lua TextAsset byte array.\"\"\"
    if not raw_data.startswith(MAGIC_HEADER):
        return raw_data  # Already plain or unencrypted
    uncompressed_len = struct.unpack('<I', raw_data[8:12])[0]
    ciphertext = raw_data[12:]
    cipher = DES.new(DES_KEY, DES.MODE_ECB)
    return cipher.decrypt(ciphertext)[:uncompressed_len]

def encrypt_lua(plain_data: bytes) -> bytes:
    \"\"\"Encrypts a Lua script string into the client's DES czjzgqde format.\"\"\"
    if plain_data.startswith(b'\\xef\\xbb\\xbf'):  # Strip UTF-8 BOM if present
        plain_data = plain_data[3:]
    cipher = DES.new(DES_KEY, DES.MODE_ECB)
    pad_len = (8 - (len(plain_data) % 8)) % 8
    padded = plain_data + bytes([1] * pad_len)
    encrypted = cipher.encrypt(padded)
    header = MAGIC_HEADER + struct.pack('<I', len(plain_data))
    return header + encrypted
```

---

### 8.3 How to Inspect & Extract Files from the APK
To read or search scripts inside the APK without unzipping the entire 2 GB file:

```python
import zipfile, io, UnityPy

apk_path = 'ROM.apk'
target_text_asset = 'MainViewTaskQuestPage'

with zipfile.ZipFile(apk_path, 'r') as apk:
    # 1. Locate the sub-zip containing framework.unity3d
    for name in apk.namelist():
        if name.startswith('assets/assets') and name.endswith('.zip'):
            subz = zipfile.ZipFile(io.BytesIO(apk.read(name)))
            for subname in subz.namelist():
                if subname.endswith('framework.unity3d'):
                    # 2. Load the AssetBundle with UnityPy
                    env = UnityPy.load(io.BytesIO(subz.read(subname)))
                    for obj in env.objects:
                        if obj.type.name == 'TextAsset':
                            d = obj.read()
                            if d.m_Name == target_text_asset:
                                raw = d.m_Script.encode('utf-8', 'surrogateescape')
                                script_text = decrypt_lua(raw).decode('utf-8', errors='ignore')
                                print(f'Extracted {d.m_Name} ({len(script_text)} chars)')
```

---

### 8.4 How to Create an OTA Patch (`patch3.zip`)
Ragnarok M supports Over-The-Air (OTA) hot-patching. When the game launches, it queries `http://<SERVER_IP>:33061/version.php` which automatically scans `web/wwwroot/127.0.0.1/res/`.

**Advantages of OTA Patches:**
- ⚡ **Zero Reinstallation**: Players receive updates instantly on client launch.
- 🎯 **Isolated & Reversible**: Creating `patch3.zip` leaves `patch.zip` and `patch1.zip` untouched. If something goes wrong, simply delete `patch3.zip` or clear client cache.
- 📦 **Automatic Versioning**: `version.php` calculates MD5 and file size, assigning the next client version automatically in `patch.meta.json`.

#### Step-by-Step Patch Creation:
1. **Load base `framework.unity3d`**:
   Load `Android/resources/script2/framework.unity3d` from `web/wwwroot/127.0.0.1/res/patch.zip` using `UnityPy`.
2. **Modify the Target Script**:
   Update `d.m_Script` of the target `TextAsset` with the newly encrypted bytes (`encrypt_lua(modified_code).decode('utf-8', 'surrogateescape')`).
   Call `d.save()`.
3. **Save AssetBundle**:
   Save `env.file.save()` to a new `framework.unity3d`.
4. **Package into `patch3.zip`**:
   Pack the updated file at path `Android/resources/script2/framework.unity3d` inside `web/wwwroot/127.0.0.1/res/patch3.zip`.
5. **Verify `patch.meta.json`**:
   Run `curl http://127.0.0.1:33061/version.php?client=400084` to verify `patch3.zip` is detected with a higher version code and valid download URL.

---

### 8.5 How to Rebuild and Sign a Full APK (If Needed)
If native libraries (`.so`), AndroidManifest, or pre-installed base assets must be changed:
1. Unzip the APK:
   `7z x ROM.apk -oextracted_apk`
2. Replace or modify files inside `assets/assets*.zip`.
3. Repack the outer APK:
   `7z a -tzip ROM_modified.apk ./extracted_apk/*`
4. Re-sign the APK using `jarsigner`:
   ```powershell
   jarsigner -keystore "client/debug.keystore" -storepass android -keypass android -sigalg SHA256withRSA -digestalg SHA-256 "ROM_modified.apk" debug
   ```
5. Re-align with `zipalign` if installing on modern Android devices:
   `zipalign -v 4 ROM_modified.apk ROM_final.apk`"""

assert old_sec in content, 'Section 8 not found'
content = content.replace(old_sec, new_sec)

with open('TROUBLESHOOTING.md', 'w', encoding='utf-8') as f:
    f.write(content)

print('TROUBLESHOOTING.md updated successfully!')
