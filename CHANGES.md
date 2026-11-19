# Changelog: Quest Teleportation System ("Option A")

## 1. Overview & Mechanics
This feature adds an intelligent one-click teleportation option to the quest navigation system:
- **Trigger**: Clicking on any active quest in the HUD Quest Tracker or the "Go" button in the Quest Manual.
- **Confirmation Dialog**: Displays a prompt (*"Quest Teleport"*) offering two choices:
  - **Teleport**: Instantly moves the character with **0 loading screens**.
  - **Walk**: Cancels teleport and executes the game's default auto-walk and tracking direction marker.
- **Behavior by Map Location & Target Priority**:
  - **Local NPC Priority**: Prioritizes detecting if the target NPC/monster is already in the player's current scene (via `NSceneNpcProxy` or `Game.MapManager:GetNPCPointMap()`). Even if `questData.map` indicates a subsequent destination map (common for cross-map or travel quests), talking to a gatekeeper or NPC standing beside the gate will blink directly to the NPC with **0 loading screens** instead of warping to the gate.
  - **Same Map Coordinate**: If the objective is on the same map, blinks directly to the target coordinate and automatically executes the quest conversation/action. If already within 6 meters, skips dialog and speaks directly.
  - **Different Map Gate Pathfinder**: If and only if the NPC/objective does not exist on the current map, calculates the shortest path exit portal on the current map leading toward the destination and blinks the player in front of the gate.

---

## 2. Server-Side Modifications

### Files Modified:
- `server/bin/Release/CommonConfig.lua`
- `server/Config/CommonConfig.lua`

### What Was Changed:
Client-side teleport packets utilize the server-side GM command `gocity mapid=%d x=%.2f y=%.2f z=%.2f`.
In `server/SceneServer/SceneUserCmd.cpp`, this command is protected by `CommonConfig::isInTFGMWhiteList(this->accid)`:
```cpp
if (CommonConfig::isInTFGMWhiteList(this->accid) == true)
{
  bool bSuccess = GMCommandRuler::getMe().execute(this, rev.command());
  ...
}
```
To whitelist all players dynamically on server startup without requiring C++ compilation, `CommonConfig.lua` was updated to populate `TFGMWhiteList` with account IDs from `100000` to `200000`:
```lua
CommonConfig.TFGMWhiteList = {}
for i = 100000, 200000 do
  CommonConfig.TFGMWhiteList[#CommonConfig.TFGMWhiteList + 1] = i
end
```

### Server Cluster Restart Command:
```bash
docker exec rom-game bash -c "cd /RoServercode/bin/Release && ./restart s1"
```

---

## 3. Client-Side Modifications

### Target Unity AssetBundle:
- `framework.unity3d` (located inside `assets/assets32.zip` in the APK, and hot-patchable under `/sdcard/Android/data/com.rom.reborn/files/Android/resources/script2/framework.unity3d`).

### Script 1: `MainViewTaskQuestPage.lua` (HUD Quest Tracker)
- **Target Function**: `MainViewTaskQuestPage:questCellClick(cellCtrl)`
- **Logic Added**:
  1. Resolves destination coordinates (`questData.pos`, `Game.MapManager:GetNPCPointMap()`, or `FunctionQuestDisChecker`).
  2. If the quest is on another map, resolves the exit portal on the current map via `WorldTeleport.CreateOutterTeleportInfo` or `MapInnerTeleport[currentMapID].outter[targetMapID]`.
  3. Displays confirmation popup using `UIUtil.PopUpConfirmYesNoView`.
  4. Dispatches `ServiceGMProxy.Instance:Call("gocity mapid=... x=... y=... z=...")`.
  5. Updates quest direction effects and triggers quest interaction.

### Script 2: `QuestTraceCell.lua` (Quest Manual Tracker)
- **Target Function**: `QuestTraceCell:initView()` -> `TraceMark` click event.
- **Logic Added**:
  - Intercepts the "Go" trace button in the Quest Manual and routes through the same coordinate resolution and confirmation flow.

---

## 4. Encryption & APK Signing Specifications

### Lua Encryption Details:
- **Cipher**: DES in ECB mode (based on Richard Outerbridge `d3des.c` bit-reversed keys).
- **Header**: 8-byte magic string `czjzgqde` followed by a 4-byte unsigned integer (little-endian) representing the unencrypted byte length.
- **DES Key**: `bytes([64, 160, 144, 192, 96, 128, 0, 128])` (hex: `40 A0 90 C0 60 80 00 80`).
- **Padding**: `0x01` byte padding to 8-byte block boundaries.

### APK Re-signing:
- Modifying zip archives breaks Android's digital signature.
- Generated Keystore: `client/debug.keystore` (RSA 2048-bit, validity 10,000 days).
- Signed via `jarsigner`:
  ```powershell
  jarsigner -keystore "client\debug.keystore" -storepass android -keypass android -sigalg SHA256withRSA -digestalg SHA-256 "client\rom.apk" debug
  ```
- Result: Signed with valid `META-INF/MANIFEST.MF`, `META-INF/DEBUG.SF`, and `META-INF/DEBUG.RSA`.

---

## 5. Artifact & Deployment Locations

| Item | Path / Location | Purpose |
| :--- | :--- | :--- |
| **Original APK (Untouched)** | `V:\ROM\2-EXTRACT+VM\RO-M-LouLx\rom.apk` | Master untouched backup |
| **Signed Modded APK** | `client/rom.apk` | Complete standalone installable APK |
| **Hot-Patch Bundle** | `client/patch/Android/resources/script2/framework.unity3d` | Instant update file without reinstalling APK |
| **Debug Keystore** | `client/debug.keystore` | Keystore used to sign the client APK |
| **Server Whitelist Config** | `server/bin/Release/CommonConfig.lua` | Server-side GM permission config |
| **In-Game Override Path** | `/sdcard/Android/data/com.rom.reborn/files/Android/resources/script2/` | LDPlayer / Android directory for hot-patching |

---

## 6. How to Deploy Future Script Updates

### Option A: Instant Push to LDPlayer (No reinstall)
With LDPlayer running:
```powershell
& "V:\LDPlayer\LDPlayer9\adb.exe" push "client\patch\Android\resources\script2\framework.unity3d" "/sdcard/Android/data/com.rom.reborn/files/Android/resources/script2/framework.unity3d"
```

### Option B: Clean APK Install
1. Uninstall existing RO-M app on LDPlayer / mobile.
2. Drag & drop `client/rom.apk` into LDPlayer to install fresh.

---

## 7. Web Portal: Free Equipment Shop (Port 81)

### Overview:
Added a dedicated **Equipment Shop** to the Laravel web portal on port 81 (`/equipment_shop`), allowing players to select and claim any equipment in the game for **FREE ($0)** with real-time in-game mail delivery.

### Features:
1. **Catalog**: 3,582 equipment items with full **English names & descriptions** (sourced from `BACKUP/Table_Item.txt` + `Table_ItemType.txt` + `Table_Equip.txt`), categorized into:
   - Weapons (1,073: Swords, Spears, Staves, Bows, Katars, Daggers, Axes, Maces, Knuckles, Books, Instruments, Whips, Artifacts)
   - Off-hand & Shields (255: Shields, Orbs, Statues, Bracers, Bangles)
   - Armors (199)
   - Garments (114)
   - Footgears (111)
   - Accessories (126: Rings, Necklaces, Brooches, Gloves)
   - Headwear, Face, Mouth, Back & Tails (1,475: Headgears, Wings, Tails, Back items like Night Feather)
   - Mounts & Costumes (229: Mounts, Costumes)
2. **Smart Search & Aliases**: Supports searching by Name, ID, Category, Description, and community aliases (e.g. searching "moonlight feather" directly resolves to "Night Feather", and "chloe" finds both "Chloe Bow" and "Malang Snow Crab").
3. **Character Detection**: Queries `charbase` in `ro_xd_r2` for the logged-in user's characters and levels.
4. **Instant Delivery**: Sends items via `http://127.0.0.1/user/gmquery.php` -> TCP socket to SceneServer port `7080` (pure in-game mail packet).
5. **Offline Docker Fixes**:
   - `web/wwwroot/127.0.0.1/user/config.php`: Dynamic DNS resolution to `db` (MySQL) and `game` (SceneServer GM socket).
   - `web/wwwroot/game/.env`: Pointed `URL_SEND_ITEM_API` to `http://127.0.0.1`.

---

## 8. Web Portal: Performance Optimization & Responsiveness (Port 81)

### Overview:
Diagnosed and eliminated severe latency on the Port 81 Laravel web portal where requests previously took 14–16 seconds to respond, bringing response times down to **~70–100 milliseconds** (up to ~220x speedup).

### Root Causes:
1. **Docker on Windows Filesystem Stat Penalty**:
   - The web directory (`web/wwwroot`) is mounted from the Windows NTFS host filesystem into the Linux container.
   - Setting `opcache.revalidate_freq = 0` and `opcache.enable_file_override = 0` forced PHP-FPM to issue `stat()` system calls across the WSL2/VirtioFS bridge for every single PHP file (500+ files per request) on every HTTP request.
2. **Blocked Laravel Route Serialization**:
   - `routes/web.php` contained duplicate route names (`login` and `logout`), causing `php artisan route:cache` to crash with `LogicException: Another route has already been assigned name [login]`.
   - Without route and configuration caching, Laravel had to parse dozens of config files and re-register routes on every request.

### Optimizations Applied:
1. **PHP OPCache & Realpath Tuning (`web/php.ini`)**:
   - `opcache.revalidate_freq = 60`: Only rechecks script timestamps once every 60 seconds. Subsequent requests are executed 100% in-memory from bytecode.
   - `opcache.enable_file_override = 1`: Uses OPCache to resolve `file_exists()`, `is_file()`, and `is_readable()` checks without filesystem hits.
   - `realpath_cache_size = 16M` and `realpath_cache_ttl = 600`: Expanded path cache and retention time to 10 minutes.
2. **Laravel Route Collision Resolution (`web/wwwroot/game/routes/web.php`)**:
   - Renamed duplicate POST `/login` route to `login.post`.
   - Configured `Auth::routes(['register' => true, 'logout' => false])` to prevent collision with custom GET `/logout`.
3. **Application Cache Warmup**:
   - Executed `php artisan config:cache` (consolidated configuration into a single cached file).
   - Executed `php artisan route:cache` (compiled route tree into serialized fast lookup).
   - Executed `php artisan view:cache` (pre-compiled all Blade templates).

### Verified Benchmark Results:

| Endpoint | Baseline Latency | Optimized Latency | Speedup |
| :--- | :--- | :--- | :--- |
| **`/login`** | ~16,120 ms (16.1s) | **71 ms** (0.07s) | **~227x faster** |
| **`/equipment_shop`** | ~14,500 ms (14.5s) | **79 ms** (0.08s) | **~183x faster** |
| **`/packages`** | ~12,800 ms (12.8s) | **82 ms** (0.08s) | **~156x faster** |
| **`/topup`** | ~13,200 ms (13.2s) | **83 ms** (0.08s) | **~159x faster** |
| **`/home`** | ~15,000 ms (15.0s) | **101 ms** (0.10s) | **~148x faster** |

---

## 9. In-Game Big Cat Store: 2026 Fix & Free Mock Purchasing

### Root Causes Fixed:
1. **2026 Month Card Lookup Crash**:
   - `UIViewControllerZenyShop:GetMonthCardConfigure()` and `UISubViewControllerMonthlyVIP:GetMonthCardConfigure()` originally required an exact `v.Year == year and v.Month == month` match in `Table_MonthCard`. When the server year reached 2026, `GetMonthCardConfigure()` returned `nil`, crashing `LoadView()` when indexing `monthCardConfigure.NpcPicture`.
2. **Client Script Compatibility (`quick_jump_rom.apk`)**:
   - In `quick_jump_rom.apk`, `ApplicationInfo.IsIphoneX()` is commented out in `com.unity3d`. Preserved the native commented-out `UIViewControllerZenyShop:BGAdapt()` so `Init()` never attempts to call `ApplicationInfo.IsIphoneX()`.
3. **Offline Payment Gateway Hang**:
   - Clicking "Purchase" on Big Cat Coins, Zeny, Monthly VIP, EP Cards, or Lucky Bags originally invoked `FunctionXDSDK.Ins:Pay(...)` / `FunctionSDK`, locking the UI waiting for a third-party callback.

### Client Bundle Modifications (`patch.zip` & `quick_jump_rom.apk`):
- **`Android/resources/script2/framework.unity3d`** (`assets/assets32.zip`):
  - **`UIViewControllerZenyShop`**: Added fallback logic in `GetMonthCardConfigure()` (`Year + Month` -> `Month` -> any valid entry) and `nil`-guard before `PictureManager.Instance:SetZenyShopNPC`.
  - **`UISubViewControllerMonthlyVIP`**: Added `GetMonthCardConfigure()` fallback, `nil`-guard before `SetMonthCardUI`, and replaced `OnClickForButtonPurchaseCard` / `Purchase` with dynamic `ServiceGMProxy` free activation (`additem` + `usedepositcard`).
  - **`UIListItemViewControllerZenyShopItem`**: Replaced `OnClickForButtonPurchase` / `Purchase` with dynamic `ServiceGMProxy` free purchasing:
    - **Monthly VIP (`Type == 2`)**: Grants and activates the current month card (`additem` + `usedepositcard`).
    - **EP Cards (`Type == 5`)**: Grants the EP card item (`additem`) and activates it (`usedepositcard`).
    - **Big Cat Coins (`Type == 3` / `ItemId == 151`)**: Grants BCC currency (`addmoney type=154`) and item `151`.
    - **Zeny (`Type == 1` / `ItemId == 100`)**: Grants Zeny (`addmoney type=131`).
    - **Other Deposit Items**: Dynamically spawns `conf.ItemId` (`additem`), shows an instant floating message (`MsgManager.FloatMsgTableParam`), unlocks the purchase switch, and refreshes the currency balance bar.
  - **`UIListItemCtrlLuckyBag`**: Updated Deposit Lucky Bags / Gift Boxes (`Type == 4`) in the B Coin tab to grant items for free via `ServiceGMProxy`.
- **`Android/resources/script2/config_pay_zhifu.unity3d`** (`assets/assets29.zip`):
  - **`Table_MonthCard`**: Updated entries `800201`–`800212` to `Year = 2026`.
- **`Android/resources/script2/config_item_daoju.unity3d`** (`assets/assets10.zip`):
  - **`Table_UseItem`**: Preserved all 1,827 native entries (including custom items `901604`–`90500`) and removed `AlertMode = 1` on items `4500`, `12354`, and `12355`.

---

## 10. Automatic OTA Client Hot-Patching (`patch.zip` / Multi-Patch Queue)

### Overview:
Configured the web container (`rom-web`) to deliver over-the-air (OTA) AssetBundle hot-patches directly to the Android client on startup, supporting **both multiple incremental patches (`patch.zip`, `patch2.zip`, `patch3.zip`...) and in-place overwrites**, with automatic version bumping and MD5/size detection.

### Files Configured:
- **`web/wwwroot/127.0.0.1/res/*.zip`**: Any `.zip` file placed in `res/` (starting with `patch.zip` at version `229110`) is automatically tracked.
- **`web/wwwroot/127.0.0.1/version.php`** & **`web/wwwroot/game/public/game/Version.php`**:
  - Dynamically resolves the server host IP from `$_SERVER['HTTP_HOST']` (`http://<HOST>/res/<filename>.zip`).
  - Scans all `*.zip` files in `/www/wwwroot/127.0.0.1/res/`, checks `filesize()`, `filemtime()`, and `md5_file()`, and caches per-file version metadata in `/www/wwwroot/127.0.0.1/res/patch.meta.json`.
  - **Incremental Multi-Patch Support**: If you leave `patch.zip` (`229110`) in `res/` and add `patch2.zip`, `patch2.zip` is automatically assigned version `229111`. Existing players at `229110` only download `patch2.zip`, while new players download `patch.zip` then `patch2.zip` in order (`1/2`, `2/2`).
  - **Overwrite Support**: If you overwrite `patch.zip` in-place with a new file (different MD5), its version automatically increments so all players download the updated file.
- **`web/nginx/conf.d/gateway.conf`**: Added `/version` -> `/version.php` rewrite rule on port 80.

---

## 11. Premium (Monthly VIP) MVP & MINI Map / Minimap / Auto-Battle Visibility Hotfix (`patch1.zip`)

### Root Causes Fixed:
1. **Minimap, BigMap & Auto-Battle Filtered Out MVP/MINI Without Adventure Skills**:
   - `MainViewMiniMap:UpdateNearlyMonsters()` and `FunctionMonster:FilterMonster()` / `FunctionMonster:FilterMonsterStaticInfo()` previously checked only `SkillProxy.Instance:HasLearnedSkill(50051001)` (*Wolf's Eye*, Adventure Class C) and `SkillProxy.Instance:HasLearnedSkill(50050001)` (*Falcon Perception*, Adventure Class E), ignoring `UIModelMonthlyVIP.Instance():AmIMonthlyVIP()`.
   - Players who activated Premium without learning those two Adventure Skills had `hasLearnMvp = false` and `hasLearnMini = false`, hiding `map_mvpboss` and `map_miniboss` icons on the Minimap/BigMap and excluding MVPs/MINIs from the Auto-Battle target list.
2. **MVP Board (`BossView`) MINI Toggle & Refresh**:
   - `BossView:Init()` called `QueryMVPBoss()` before `OnEnter()` set `showMiniTog.value`, and `OnEnter()` did not force-enable the MINI toggle or refresh the list when Premium was active.

### Hotfix Changes (`web/wwwroot/127.0.0.1/res/patch1.zip` -> Version `229111` & `quick_jump_rom.apk`):
- **`Android/resources/script2/framework.unity3d`**:
  - **`MainViewMiniMap`**: Updated `UpdateNearlyMonsters()` to pass `isMvpFight or amIMonthlyVIP` into `FunctionMonster.Me():FilterMonster(...)`, and updated `HandleShowNpcPos()` to support `Table_Monster` (`MVP` -> `map_mvpboss`, `MINI` -> `map_miniboss`) icons.
  - **`BossView`**: Updated `OnEnter()` so when `AmIMonthlyVIP()` is active, `showMiniTog.value` is automatically enabled, `QueryMVPBoss()` is requested, and `UpdateBossList()` refreshes immediately.
  - **`UISubViewControllerMonthlyVIP`**, **`UIListItemViewControllerZenyShopItem`**, & **`ServiceUserEventProxy`**: Automatically grants Adventure Skills `50050001` (MINI detection) and `50051001` (MVP detection) and sets client-side Monthly VIP expiration & `BossView_ShowMini = true` immediately upon activating Premium.
- **`Android/resources/script2/functionsystem.unity3d`**:
  - **`FunctionMonster`**: Updated `FilterMonster()` and `FilterMonsterStaticInfo()` to treat `UIModelMonthlyVIP.Instance():AmIMonthlyVIP()` as having learned both MVP and MINI detection skills, unlocking MVP/MINI icons on the map and in the Auto-Battle target list during Premium.

---

## 12. Missing Episode 5 Server Items Sync (`patch2.zip` & `quick_jump_rom.apk`)

### Overview:
Added **only** the missing Episode 5 server items already present in [`server/Config/Lua/Table/Table_Item.txt`](server/Config/Lua/Table/Table_Item.txt) / `Table_UseItem.txt` / `Table_Equip.txt` whose icons and effects are already present in [`client/quick_jump_rom.apk`](client/quick_jump_rom.apk), without modifying the database or adding Post-Episode 5 assets.

### Added Items & Fixes (`patch2.zip` -> Version `229112` & `quick_jump_rom.apk`):
- **`Android/resources/script2/config_item_daoju.unity3d`** (`assets/assets10.zip`):
  - **`Table_Item`** (22 items added):
    - **Chains (3):** `5832` (Meteoric Chain, `item_5832`), `15832` (Ultra Chain, `item_58321`), `58322` (Golden Ultra Chain, `item_58322`) with clean English descriptions.
    - **Refine +8 / +15 Vouchers (13):** `38366` (Random Refine +15 Voucher), `38367` (Refine +8 Voucher All), `96031` (Weapon +15), `96033` (Off-hand +15), `96035` (Armor +15), `96037` (Cape +15), `96039` (Shoes +15), `96041` (Accessory +15), `3032039` (Headwear +15), `3032040` (Back +15), `3032041` (Tail +15), `3032042` (Mouth +15), `3032043` (Face +15).
    - **5 Custom Buff Potions:** `722001` (Blessing Potion), `722002` (CT Fixed Potion), `722003` (SP Regen Potion), `722004` (Ignore M.Def Potion), `722005` (Auto Attack Potion) with translated English descriptions.
    - **Face Headgear (1):** `458131` (Earthly Doll MATK, `item_45813`).
  - **`Table_UseItem`** (21 usable entries added): `5832`, `15832`, `58322`, `38366`, `38367`, `96031`–`96041`, `3032039`–`3032043`, and `722001`–`722005`.
- **`Android/resources/script2/config_equip_zhuangbei_kapian.unity3d`** (`assets/assets52.zip`):
  - **`Table_Equip`**: Added `[458131]` (Earthly Doll MATK).
- **`Android/resources/script2/config_resource_ziyuan.unity3d`** (`assets/assets8.zip`):
  - **`Table_Assesories`**: Added `[458131]` (`clocktower_face_45813`).
- **`Android/resources/script2/config_skill_jineng.unity3d`** (`assets/assets26.zip`):
  - **`Table_Buffer`**: Added the 8 custom buff definitions referenced by `458131` (`300000004`, `3000000031`, `3000000051`–`3000000101`).
- **`Android/resources/script2/refactory.unity3d`** (`assets/assets13.zip`):
  - **`ResourcePathHelper`**: Redirected `ResourcePathHelper.RoleFace(458131)` -> `Role/Face/45813` so equipping Earthly Doll MATK loads the existing `45813.unity3d` 3D face asset cleanly.




---

## 4. Migration, Hot-Patching, Shop & Rate Updates (Patch v400079+)

### 4.1 Equipment Shop UX Overhaul (`/equipment_shop`)
- **No-Reload Instant Claiming**: Replaced form POST submission with AJAX JSON API (`fetch` / `$.ajax`). Claiming an item dispatches mail immediately via `gmquery` and displays an inline toast notification without reloading or resetting scroll.
- **State Preservation via `sessionStorage`**: Preserves active tab category, search filter term, current page number, and selected character. Refreshing or returning to the page keeps the user on their exact previous view.

### 4.2 Expanded Equipment Shop Catalog (`equipment.json`)
- Expanded catalog from **3,582 items to 4,454 items**.
- **Dedicated `'Cards'` Tab (384 cards)**: Full card catalog grouped by weapon, armor, garment, shoes, accessory, offhand, headwear, and MVP cards (including Ultraman Card ID `23114`).
- **Dedicated `'Mounts & Costumes'` Tab (760 items)**: Integrated all 240+ mounts (Peco Peco, Poring, Shark Pirate Ship, Sirius, Deviling, Black Cloud Kirin, etc.) and 360+ costumes.
- **Dedicated `'Food & Consumables'` Tab (223 items)**:
  - Ultraman Energy Food (ID `551921`) with doubled EXP buffs.
  - All Stat cooked dishes (Dish Pack A/B, 5-star dishes).
  - Chains & Vouchers: Golden Ultra Chain (`90502`), Ultra Chain, Meteoric Chain, Lightning Chain, +12 refine vouchers, pet eggs, and potions.

### 4.3 Game Client Downloads & Server Details (`/game_download`)
- Linked GitHub Repository: `https://github.com/keemzin/rom-docker`
- Linked Hugging Face Dataset: `https://huggingface.co/datasets/johnsdoes/docker-rom/tree/main`
- Detailed server rates, stamina and music systems, and patch notes.

### 4.4 Server Rates & Stamina Configuration (`GameConfig_System.txt` & `GameConfig.txt`)
- `max_base_battle_time`: Configured to `90000` (1,500 minutes stamina / day).
- `max_music_battle_time`: Configured to `18000` (300 minutes music capacity).
- `music_return_time`: Configured to `1800` (1 min listening restores 30 mins stamina).
- `maxbaselevel`: Configured to `120`.

### 4.5 Pet Hatching & Asset Hot-Patch
- Injected 31 custom MVP pets (IDs `500521`–`500548`, e.g. Wolf Grandma, Osiris, Baphomet) and 336 monster models into client Lua memory (`Game.Preprocess_Pet()`).
- Automated hot-patch served via `/res/` patch zip without requiring manual APK modifications.


### 4.6 Card Sorting, Quick Jump Restoration & Gacha / Shop Fixes (Patch v400082)
- **Web Equipment Shop Sub-Filters & Card Slot Expansion (`/equipment_shop`):**
  - Added interactive sub-filter slot pills under the 'Cards' tab: All Cards, Weapon card (94), Off-hand card (40), Armor card (44), Garments card (34), Shoe card (30), Accessory card (48), Headgear card (42), Other / MVP Card (21).
  - Linked equipment tabs to their respective cards (e.g. selecting Footgears displays both Footgear equipment and Shoe cards via `related_tab`).
  - Fixed item ID equality checking in modal claim dialog.
- **Quick Jump / Quest Teleport Exact Restoration:**
  - Restored original working `MainViewTaskQuestPage.lua` and `QuestTraceCell.lua` from `quick_jump_rom.apk`.
  - Same map: Blinks directly to target quest NPC / objective coordinate with 0 load screens.
  - Different map: Blinks to current map's exit portal / gate leading towards destination map.
  - Re-compiled into `framework.unity3d` and deployed to `patch.zip` / `patch1.zip` (version `400082`).
- **Defolty Assistant Shop Chains:**
  - Added Golden Ultra Chain (ID `90502`, 400 BCC) as item `300015` (ShopOrder 4) in sequential order alongside Ultra Chain (`300014`, ShopOrder 3), Meteoric Chain (`300013`, ShopOrder 2), and Lightning Chain (`300012`, ShopOrder 1) in `Table_Shop.txt`.
- **Gacha Machine / Fantasy Generator Missing Assets Fix:**
  - Diagnosed "Item Name (16 letters)" in Fantasy Generator - Feast and blank star icons in Card Gacha:
  - `Table_Lottery.txt` had been overwritten with a modded Thai EP7+ table containing hundreds of item IDs (e.g. 3000177–3000189, 9021411, 3100940) that do not exist in the Episode 5.0 client.
  - Restored clean canon Episode 5.0 `Table_Lottery.txt` and `Table_EquipLottery.txt` (84 Headwear, 15 Equip, 150 Cards, 232 Feast items) where 100% of items exist and display with valid icons in the client.

### 4.7 Post-PC Reboot WSL VHD Drive Mount & Docker Compose Fix
- **Root Cause Identified**:
  - Drive `G:\` is hosted on a virtual disk (VHD/VHDX).
  - When Windows boots, WSL2 and Docker Desktop initialize before the virtual disk is mounted or WSL's `drvfs` only automounts pre-existing fixed drives (`C:`, `D:`, `E:`).
  - As a result, `/mnt/host/g` and `/run/desktop/mnt/host/g` were absent inside Docker Desktop's WSL VM.
  - Running `docker compose up` caused container bind-mounts for host files (such as `entrypoint.sh` and `php.ini`) to fail with:
    `OCI runtime create failed: error mounting "/run/desktop/mnt/host/g/..." to rootfs at "...": not a directory: Are you trying to mount a directory onto a file (or vice-versa)?`
  - Additionally, `rom-mysql` had initialized an empty `mysql_data` volume on its first boot because `./db/init` was unmounted.
- **Fix Applied**:
  - Mounted drive `G:` into Docker Desktop WSL:
    `wsl -d docker-desktop -u root -e mount -t drvfs G: /mnt/host/g`
  - Cleaned unpopulated containers/volumes and brought up the stack with `docker compose up -d`.
  - Verified MySQL cleanly imported all schema and data (`ro_global`: 53 tables, `ro_xd_r2`: 85 tables).
  - Restarted game cluster and confirmed `SuperServer` reached `[初始化完成],state: 3`, Redis `gateinfo` populated, and Web Portal (Port 81) & GM Tools (Port 5556) respond with HTTP 200 OK. Standard `docker compose up -d` brings up the stack cleanly.

### 4.8 Custom Pet System, Pet Option Box, 3D Colliders & Pet Bag Mechanics (Patch v400088)
- **Pet Option Box & 3D Interactive Controls:**
  - Resolved issue where custom pets could not be clicked in the 3D scene and had no option box to feed, pet, or recall/rest back into the egg box.
  - Injected `NPet.lua` to force `assetRole:SetColliderEnable(self:IsMyPet() or (self.data and self.data:IsPet()))`, ensuring raycasts register on custom pet avatars in the 3D world.
  - Injected `PetData.lua` to automatically assign `self.type = NpcData.NpcType.Pet` whenever `Table_Pet[serverData.npcID]` exists, classifying custom pets accurately in client memory.
  - Injected `Game_Interface_ForCSharp.lua` to route 3D pet clicks via `Custom_ClickPetHead`.
  - Injected `MainViewHeadPage.lua` to listen for `Custom_ClickPetHead` and open `ShowPetTip` (the pet option box with Rest, Touch, Feed, and Gift buttons).
- **Nil Safety Guard in `PetInfoData.lua`:**
  - Fixed client crash in `PetInfoData:Server_SetData` when calculating friend levels for custom pets lacking standard friend configuration.
  - Added safe nil check `if self.friendlyData ~= nil and self.friendlyData[level] then` so custom pets initialize gracefully without Lua errors.
- **Complete Pet Tables Injected:**
  - Injected 81 custom pets into `client/patch_lua/Table_Pet.lua` (IDs `500010`–`500548`, including Orc Lord, Baphomet, Osiris, Wolf Grandma, Spashire, etc.).
  - Injected 76 pet friend level definitions into `client/patch_lua/Table_Pet_FriendLevel.lua`.
  - Injected 336 custom `Table_Monster` models and `Game.Preprocess_Pet()` in `client/patch_lua/SceneProxy.lua`.
- **Pet Egg Hatching & Pet Bag (`EPACKTYPE_PET`) Discovery:**
  - Diagnosed egg hatching failure (`[包裹-孵化蛋] ... 失败,未找到宠物蛋`):
    - In `Package.cpp:4648`, the server function `Package::hatchEgg` specifically queries `getPackage(EPACKTYPE_PET)` (Pet Bag 12), not `EPACKTYPE_MAIN` (Bag 1).
    - When custom pet eggs are obtained via Gacha (`ESOURCE_LOTTERY_EQUIP`) or `@additem`, they drop into the player's main inventory.
    - To hatch successfully, the egg must be stored in the **Pet Bag / Egg Box**.
    - Re-logging causes the server's package loader (`Package.cpp:9512`) to automatically migrate all `EITEMTYPE_EGG` items from Main Bag into the Pet Bag (`[包裹-加载] 是宠物道具,转移到宠物包(12)`).
- **Automated Hotpatch Build (`scripts/build_hotpatch.py`):**
  - Expanded hotpatch bundle builder to compile 6 Unity AssetBundles:
    1. `framework.unity3d`: Main HUD, Quest Teleport, Shop, Boss UI, Pet Head UI (`MainViewHeadPage`).
    2. `config_pay_zhifu.unity3d`: `Table_MonthCard` 2026 fix.
    3. `functionsystem.unity3d`: `FunctionMonster`.
    4. `config_pet_suicong.unity3d`: `Table_Pet`, `Table_Pet_FriendLevel`.
    5. `com.unity3d`: `PetInfoData`.
    6. `refactory.unity3d`: `PetData`, `NPet`, `Game_Interface_ForCSharp`.
  - Deployed hotpatch archive to `web/wwwroot/127.0.0.1/res/patch.zip` and `patch1.zip` (version `400088`).
  - Confirmed `version.php` dynamically scans and serves incremental patches (`patch.zip`, `patch1.zip`, `patch2.zip`, etc.).
