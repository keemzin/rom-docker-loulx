# 📦 Ragnarok M (LouLx EP5) - Over-The-Air (OTA) Patches

This directory contains the latest pre-built client OTA patches and metadata manifest. When the game client launches, it queries `version.php` / `patch.meta.json` and automatically downloads and unpacks any newer patches over-the-air.

---

## 🚀 Quick Setup (How to Install)

After extracting `server.zip` and `wwwroot.zip` from Hugging Face:

### Method 1: Automated 1-Click (Recommended)
Run from the repository root:
```powershell
python scripts/install_patches.py
```
This automatically copies the client OTA hotpatches to `./web/wwwroot/127.0.0.1/res/` and updates the server tables in `./server/`.

### Method 2: Manual Copy
1. **Client Patches**: Copy `patch.zip`, `patch1.zip`, `patch2.zip`, and `patch.meta.json` into `./web/wwwroot/127.0.0.1/res/`.
2. **Server Tables**: Copy `patches/server_tables/Release/*.txt` into `./server/bin/Release/Lua/Table/`, and `patches/server_tables/Config/*.txt` into `./server/Config/Lua/Table/`.

This ensures your local Nginx server immediately serves the latest version **400100** hotpatches with all custom pet skills, animations, quest quick-jump, and bug fixes to connecting game clients.

---

## 📋 Patch Catalog & Changelog

| Archive | Version | Size | Description & Contents |
| :--- | :---: | :---: | :--- |
| **`patch.zip` / `patch1.zip`** | `400089` | ~16.5 MB | **Core Quality-of-Life & Bug Fixes**: <br>• **2026 Monthly VIP Card Fix**: Fixes client crash on the month card tab (`Table_MonthCard.lua`).<br>• **Big Cat Store Mock Payments**: Free Big Cat Coins and mock recharge system (`UIViewControllerZenyShop.lua`).<br>• **VIP Mini-Map Radar**: Auto-detects Mini & MVP bosses on the mini-map (`FunctionMonster.lua`). |
| **`patch2.zip`** | **`400100`** | **~25.0 MB** | **All-In-One Overhaul: Custom Pets, Combat Skills & Instant Quest Quick Jump**: <br>• **Complete 28 MVP/Mini-Boss Pets**: Unique egg hatching, 3D monster models, interactive touch events, and avatar option menus (`Table_Pet.lua`, `Table_Pet_FriendLevel.lua`, `SceneProxy.lua`).<br>• **Instant Quest Auto-Complete & Quick Jump**: 0-load screen quest teleporting directly to objectives and interactive dialog (`MainViewTaskQuestPage.lua`, `QuestTraceCell.lua`, `UniqueConfirmView.lua`).<br>• **Verified Combat Skills**: Fixed missing visual effects and animations (`Table_Skill.lua` inside `config_skill_jineng.unity3d`):<br>&nbsp;&nbsp;- **Eddga**: Blazing Flame (`MagnumBreak_attack` + `FireAttributeHit` impact with `use_skill` roar).<br>&nbsp;&nbsp;- **Bloody Knight & Thanatos**: Dark Blow (`darkhole_attack` + `drakattributehit` shadow strike).<br>&nbsp;&nbsp;- **Wolf Grandma**: Frenzied Scratch (`SonicBlow` + `ragingpalmstrike_hit` claw impact).<br>&nbsp;&nbsp;- **Spashire & Stormy Knight**: Cold Bolt (removed freezing `reading` cast pose).<br>• **Normalized Attack Speed**: Balanced pet attack intervals to `AtkSpd = 1.2` (~0.8s cooldown, eliminating machine-gun skill spam). |
| **`patch.meta.json`** | Latest | ~500 B | **Version Manifest**: Read by the mobile client on launch to compare current local patch versions against server versions and trigger automatic downloads. |

---

## 🛠️ Rebuilding Patches From Lua Source

All unencrypted, human-readable Lua source files are tracked in `client/patch_lua/`.

To compile, encrypt, and generate a new hotpatch archive:
```powershell
python scripts/build_hotpatch.py patch2.zip --all
```
This will:
1. Extract the base Unity asset bundles from `client/loulx-rom.apk`.
2. Encrypt the modified Lua scripts using the LouLx AES-256-CBC cipher.
3. Repack them into `patch2.zip`, bump the version in `patch.meta.json`, and output the files to `./web/wwwroot/127.0.0.1/res/`.
4. Copy the newly generated `patch2.zip` and `patch.meta.json` into this `patches/` folder to commit and share on GitHub!
