# 🗡️ Ragnarok M: Eternal Love (EP 5.0) - LouLxGame + SkyArc Merged Stack

Containerized, all-in-one Docker stack for **Ragnarok M: Eternal Love (Episode 5.0)**, merging the content-rich **LouLxGame** release with **SkyArc's** production-ready container architecture, web portal, and in-game GM tooling.

🐙 **GitHub Repository:**  
👉 [**github.com/keemzin/rom-docker-loulx**](https://github.com/keemzin/rom-docker-loulx)

📦 **Download Server Assets & 64-Bit Client:**  
👉 [**huggingface.co/datasets/johnsdoes/docker-rom/tree/main/loulx**](https://huggingface.co/datasets/johnsdoes/docker-rom/tree/main/loulx)

---

## 🌟 Origins & Project Lineage

This project unites two major community milestones from RaGEZONE:

1. **[LouLxGame Episode 5.0 Release](https://forum.ragezone.com/threads/ragnarok-m-ep5-vm-apk-pc-version-offline-new-mount-costume-2d-3d-camera-and-more-apk-support-android-14.1256253/)**:
   * Native **64-bit Android Client (`ROM.apk`)** supporting Android 9 through Android 14 and modern 64-bit emulators (LDPlayer 9, MuMu Player).
   * **240+ New Mounts & Costumes** (Peco Peco, Poring mounts, Shark Pirate Ship, Sirius, Deviling, Black Cloud Kirin, 2D/3D camera modes).
   * Massive catalog of **353+ cards** (including full Shoe/Footgear cards and MVP cards).
   * Modernized EP5 game tables and Lua client scripts.

2. **[SkyArc Docker Server Stack](https://forum.ragezone.com/threads/ragnarok-m-english-patch-99-rom-mobile-korea-cn-2x-apk-vm-video-tutorial.1250510/)**:
   * Complete multi-container microservice stack: MySQL 5.7, Redis 6, PHP 8.2 FPM Web Gateway, and 21 C++ game cluster binaries with Swoole Trade Server.
   * Player dashboard on port 81 (Registration, Equipment Shop, Stamina resets, Server Info).
   * In-game Big Cat Store mock payment bypass (claim BCC, Zeny, and Monthly VIP cards for $0 in real-time).

---

## ⚡ Key Enhancements in This Merged Release

### 1. Unified Web & In-App Authentication
* **Register Anywhere**: Players can register via the web browser at `http://<SERVER_IP>:81` or **directly inside the mobile game client**.
* **Seamless API Proxy**: Nginx automatically proxies client `/login`, `/register`, and `/api/update` requests directly into Laravel, with 0 additional setup required.

### 2. No Fixed IP Server Binding (Localhost / 0.0.0.0 Architecture)
* The game servers, database, cache, and web gateway connect internally via container hostnames (`db`, `redis`, `localhost`).
* All external ports bind cleanly to `0.0.0.0` on your host machine.
* **No more hardcoded external WAN IPs** inside server configuration files or binaries.

### 3. Mobile Client Networking (Microsoft Loopback Adapter - No VMware Needed)
The LouLx mobile client is configured to connect to IP **`192.168.128.129`**.

**VMware is NOT required.** Docker Desktop binds all container ports to `0.0.0.0` on your host machine. As long as any local network interface on Windows holds `192.168.128.129`, Windows immediately routes traffic to Docker containers.

* **Recommended (Priority): Microsoft KM-TEST Loopback Adapter**
  * Built directly into Windows (100% free, native, zero 3rd-party software).
  * Stays permanently active even when disconnected from Wi-Fi or Ethernet.
  * Completely isolated—zero interference with physical routers, switches, or VLANs.
* **Automated Setup**: Run `powershell -ExecutionPolicy Bypass -File scripts\setup_loopback.ps1` (as Administrator).
* **Alternative Options**:
  * *VMware Workstation Users*: If you already have VMware installed, you can simply set the **VMware Network Adapter VMnet8** IP to `192.168.128.129` (Subnet: `255.255.255.0`, Gateway: blank).
  * *Hyper-V Users*: Create an internal switch: `New-VMSwitch -Name "RO-Internal" -SwitchType Internal` and assign `192.168.128.129/24`.
* **Tailscale Remote Play**: If playing over Tailscale from a remote phone or laptop, approve subnet route `192.168.128.0/24` in your Tailscale Admin Console. See [LOOPBACK_ADAPTER_GUIDE.md](docs/LOOPBACK_ADAPTER_GUIDE.md) for full details.

### 4. Over-The-Air (OTA) Hotpatching Engine
* Modifying Lua client scripts no longer requires unpacking or recompiling the 2GB APK!
* The stack includes an automated AES-256-CBC bundle compiler:
  ```powershell
  python scripts/build_hotpatch.py patch3.zip --all
  ```
* Edits in `client/patch_lua/` (framework, pet configurations, skill tables) are automatically encrypted into Unity TextAssets, repacked into `patch3.zip` under `web/wwwroot/127.0.0.1/res/`, and version-bumped in `patch.meta.json`. Includes full compilation of `config_skill_jineng.unity3d` (`Table_Skill`) and `config_pet_suicong.unity3d` (`Table_Pet`).
* Players receive client patches over-the-air upon game launch.

### 5. Web Equipment Shop (Port 81)
* Web store at `http://localhost:81/equipment_shop` with **4,450+ items** cataloged.
* Instant background AJAX mail delivery (items arrive in player's in-game mailbox in 1 second without page reload).
* Dedicated tabs for **Weapons**, **Armors**, **Footgears**, **Mounts & Costumes (760 items)**, **Food & Consumables (Ultraman dishes, +15 refine vouchers)**, and **Cards (353 cards)** with slot sub-filters (Shoes, Off-hand, Accessories, Headwear, MVP).

### 6. Custom Pet System & 3D Interactive Controls
* **Complete Pet Catalog (81 Pets & 76 Friend Levels)**: Full support for 28 custom MVP, Mini-Boss, and Special pets with custom 3D monster models, interactive touch events, and customized combat/passive skill profiles (delivered via OTA `patch3.zip`).
* **Unique Lore-Accurate Skills**: Unlike releases where all custom pets shared duplicate placeholder skills, each MVP pet has dedicated active combat attacks and master stat buffs:
  * **Baphomet (`900166`)**: Sonic Blow + Crit.Dmg Up + Devil's Strength
  * **Golden Thief Bug (`900172`)**: Knocking Attack + Refine Atk + Solid Shell (Damage Reduction)
  * **Orc Lord (`900157`) / Orc Hero (`900158`)**: Heavy Cleave + Atk Up + Super Vigor (Max HP) / Stun Resistance
  * **Moonlight Flower (`900156`)**: Advance Attack + Attack Speed Up + Gale Style (Move Speed & Flee)
  * **Osiris (`900155`)**: Undead Attack + M.Atk Up + Dead Nemesis
  * **Arc Angeling (`900170`)**: Full Recovery (Heal) + Healing Effect Up + Angel's Love
  * **Phreeoni (`900178`)**: Heavy Bite + Hit Rate Up + Great Appetite
  * **Thanatos (`900181`)**: Dark Blow + Crit.Dmg Up + Liquidation (Boss Damage)
* **3D Interaction & Option Menu**: Click custom pets directly in the 3D world or tap the pet avatar in the top-left HUD to open the option box (`ShowPetTip` - Feed, Touch, Gift, and Rest / Recall to Pet Egg Box).
* **Egg Hatching & Skill Rolling Workflow**:
  - In RO Mobile, the game server's `Package::hatchEgg` checks the dedicated **Pet Bag / Egg Box (`EPACKTYPE_PET`)**.
  - Custom eggs acquired via Gacha or `@additem` enter the main inventory; players simply move the egg into the Pet Egg Box tab (or relog, which auto-sorts pet eggs into the Pet Bag), then click **Hatch** to summon the pet.
  - **Important for Existing Pets**: Pet skill IDs are rolled from `Table_Pet` at the moment an egg is hatched and saved permanently to the database character blob (`setSkillIDs`). Any pet hatched before this update retains the older duplicate skills in its save data. To get the new unique skill profile, simply spawn and hatch a fresh egg (e.g. `@additem 900165 1` for Bloody Knight) or use a Pet Skill Reset item.
  - **Combat Skill Casting**: Pet active combat skill casting is driven by `Table_MonsterSkill.txt`. All 28 custom pets have their active attack skills configured so they cast their signature attacks during battle.
  - **Visual Effects & Skill Animations**: All 28 custom pet active skills are verified and cross-checked against native EP5 APK effect assets. Broken/missing effect prefabs (such as missing `HotFlame_Atk`, `DarkAtk_Atk`, `CrazyClaw_hit`) and invalid humanoid cast poses (`reading`) have been replaced with native working effects (`MagnumBreak_attack`, `FireAttributeHit`, `darkhole_attack`, `drakattributehit`, `ragingpalmstrike_hit`) and injected into `config_skill_jineng.unity3d` via OTA `patch3.zip`.
  - **Normalized Attack Speed**: Pet attack speeds have been balanced and normalized across all custom pets (`AtkSpd = 1.2`, ~0.8s cooldown) for smooth, natural combat pacing.

#### 🐾 Custom MVP & Mini-Boss Pet Egg Catalog
| Pet ID | Name | Egg ID | Type | Role / Primary Buffs |
| :---: | :--- | :---: | :---: | :--- |
| `500521` | **Wolf grandma** | `900154` | Mini | Aspd Up, Gale Style (Flee & Speed) |
| `500522` | **Osiris** | `900155` | MVP | M.Atk Up, Dead Nemesis (Magic Blast) |
| `500523` | **Moonlight Flower** | `900156` | MVP | Attack Speed Up, Gale Style |
| `500524` | **Orc Lord** | `900157` | MVP | Physical Atk Up, Super Vigor (Max HP) |
| `500525` | **Orc Hero** | `900158` | MVP | Hit Rate Up, Stun Resistance |
| `500526` | **Atroce** | `900159` | MVP | Physical Atk Up, Furious Frenzy |
| `500527` | **Doppelganger** | `900160` | MVP | Sonic Blow, Aspd Up, Sharp (Crit) |
| `500528` | **Kobold Leader** | `900161` | MVP | Spiraling Pierce, Crit Rate Up, War Horn |
| `500529` | **Detarderous** | `900162` | MVP | Magic Fire (Dragon Breath), Atk Up, Fire Burn |
| `500530` | **Owl Baron** | `900163` | MVP | Discharging Ray, M.Atk Up, Variable Cast Reduction |
| `500531` | **Thiefbug** | `900164` | Mini | Aspd Up, Flee Up, Greed Loot |
| `500532` | **Bloody Knight** | `900165` | MVP | Dark Blow, Refine Atk, Liquidation (Boss Dmg) |
| `500533` | **Baphomet** | `900166` | MVP | Sonic Blow, Crit.Dmg Up (+30%), Devil's Strength |
| `500534` | **Time Holder** | `900167` | MVP | Napalm Vulcan, Refine M.Atk, Bullet Time (Cooldown) |
| `500535` | **Spashire** | `900168` | MVP | Cold Bolt, M.Atk Up, Ice Ode (Water Amp) |
| `500536` | **Stormy Knight** | `900169` | MVP | Cold Bolt, Crit Rate Up, Freezing Flame |
| `500537` | **Arc Angeling** | `900170` | MVP | Full Recovery (Heal), Healing Effect Up, Angel's Love |
| `500538` | **Kaho** | `900171` | MVP | Fire Burst, Atk Up, Incinerate |
| `500539` | **Golden Thief Bug** | `900172` | MVP | Shield Knock, Refine Atk, Solid Shell (Damage Reduct) |
| `500540` | **Deviling** | `900173` | Mini | Dark Invasion, Atk Up, Heart of Sin |
| `500541` | **Drake** | `900174` | MVP | Sharp Stab, Refine Atk, Amphibious |
| `500542` | **Strouf** | `900179` | Mini | Water Torrent, M.Atk Up, Ocean Magic |
| `500543` | **Goblin Leader** | `900176` | MVP | Pierce, Crit Rate Up, Stir Trouble |
| `500544` | **Mistress** | `900175` | MVP | Discharging Ray, Aspd Up, Insect Dance |
| `500545` | **Maya** | `900177` | MVP | Earth Tremor, Hit Rate Up, Stone Skin (Defense) |
| `500546` | **Phreeoni** | `900178` | MVP | Heavy Bite, Hit Rate Up, Great Appetite |
| `500547` | **Eddga** | `900180` | MVP | Blazing Flame, Atk Up, Burning Body |
| `500548` | **Thanatos** | `900181` | MVP | Dark Execution, Crit.Dmg Up, Liquidation (Boss Dmg) |

---

## 🏛️ Stack Architecture

```
                    +-----------------------------+
                    |       Incoming Traffic      |
                    +--------------+--------------+
                                   |
         +-------------------------+-------------------------+
         |                         |                         |
         v                         v                         v
+-----------------+       +-----------------+       +-----------------+
| rom-web-lolx    |       | rom-game-lolx   |       | rom-mysql-lolx  |
| (Ports 80/81/   |       | (Ports 7080-    |       | (Port 3306)     |
|  5556/33061)    |       |  7082, 7050,    |       | ro_global       |
| Nginx + PHP 8.2 |       |  6091, 14288)   |       | ro_xd_r2        |
| GM & Reg Portal |       | 21 C++ Servers  |       +--------+--------+
+-----------------+       | + Trade Server  |                ^
         |                +--------+--------+                |
         |                         | (socat bridge)          |
         +-------------------------+-------------------------+
                                   |
                          +--------v--------+
                          | rom-redis-lolx  |
                          | (Port 6379)     |
                          | Session/Cache   |
                          +-----------------+
```

---

## 🚀 Quick Start Guide

### Step 1: Clone Repository
```bash
git clone https://github.com/keemzin/rom-docker-loulx.git
cd rom-docker-loulx
```

### Step 2: Download Server & Client Assets
Download the pre-configured archives from Hugging Face:  
👉 [**huggingface.co/datasets/johnsdoes/docker-rom/tree/main/loulx**](https://huggingface.co/datasets/johnsdoes/docker-rom/tree/main/loulx)

Extract each file into the repository root:
1. **`loulx/server.zip`** -> Extract into `./server/`
2. **`loulx/wwwroot.zip`** -> Extract into `./web/wwwroot/`
3. **`loulx/init.zip`** -> Extract into `./db/init/`
4. **`loulx/ROM.apk`** -> Install on Android or drag-and-drop into LDPlayer 9 / MuMu!

### Step 3: Configure Environment
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
*(Default settings are pre-configured for `192.168.128.129` and standard game ports).*

### Step 4: Configure Network Adapter (Microsoft Loopback Adapter - Priority)
The game client connects to `192.168.128.129`. You do **not** need VMware installed—use Windows' native Microsoft Loopback Adapter:

#### Option A: Automated PowerShell Setup (Recommended)
Open PowerShell as **Administrator** and run:
```powershell
powershell -ExecutionPolicy Bypass -File scripts\setup_loopback.ps1
```

#### Option B: Manual GUI Setup
1. Press <kbd>Win</kbd> + <kbd>R</kbd>, type **`hdwwiz.exe`**, and press **Enter**.
2. Select **"Install the hardware that I manually select from a list (Advanced)"** $\rightarrow$ **Next**.
3. Select **Network adapters** $\rightarrow$ **Next**.
4. In the left pane, select **Microsoft**. In the right pane, select **Microsoft KM-TEST Loopback Adapter** $\rightarrow$ **Next** $\rightarrow$ **Finish**.
5. Press <kbd>Win</kbd> + <kbd>R</kbd>, type **`ncpa.cpl`** $\rightarrow$ press **Enter**.
6. Right-click the new adapter (e.g. *Ethernet 2*) $\rightarrow$ **Properties**.
7. Select **Internet Protocol Version 4 (TCP/IPv4)** $\rightarrow$ **Properties**:
   * Select: **Use the following IP address**
   * **IP address:** `192.168.128.129`
   * **Subnet mask:** `255.255.255.0`
   * **Default gateway:** *(leave blank)*
8. Click **OK**.

*(Alternative: If you already have VMware Workstation installed, you can simply use **VMnet8** with the same IP and subnet).*
For troubleshooting and advanced options, see [LOOPBACK_ADAPTER_GUIDE.md](docs/LOOPBACK_ADAPTER_GUIDE.md).

### Step 5: Start the Server Stack
Launch the container cluster using standard Docker Compose:
```bash
docker compose up -d
```

Check game cluster readiness:
```bash
docker exec rom-game-lolx tail -n 20 /RoServercode/bin/Release/log/xd/r2_s1/SuperServer.log
```
*(When you see `[初始化完成],state: 3`, all 21 servers are online and ready for logins!)*

### Step 6: Connect & Play
* Launch **ROM.apk** on your device or emulator.
* Register directly in the game client login screen, or via `http://localhost:81` / `http://192.168.128.129:81`.
* Enjoy Ragnarok M Episode 5.0!

---

## 🔄 Building OTA Client Hotpatches

All unencrypted, human-readable Lua source scripts are saved in **`client/patch_lua/`**:
- `Table_Pet.lua` & `Table_Pet_FriendLevel.lua`: Complete 81 custom pets and 76 friend level configurations.
- `PetInfoData.lua`: Nil safety guard preventing friend level calculation crashes on custom pets.
- `PetData.lua` & `NPet.lua`: Type enforcement (`NpcData.NpcType.Pet`) and 3D collider enable for player-owned custom pets.
- `Game_Interface_ForCSharp.lua` & `MainViewHeadPage.lua`: 3D pet touch events and pet avatar option menu popup (`ShowPetTip`).
- `SceneProxy.lua`: 336 custom monster client models preprocessed for pet rendering.
- `MainViewTaskQuestPage.lua` & `QuestTraceCell.lua`: 0-load screen quest teleport.
- `UIViewControllerZenyShop.lua` & `UIListItemViewControllerZenyShopItem.lua`: Big Cat Store mock payment.
- `Table_MonthCard.lua`: 2026 month card crash fix.
- `FunctionMonster.lua`: VIP MVP & Mini-Boss map detection.

The builder packages these into 6 Unity AssetBundles (`framework`, `config_pay_zhifu`, `functionsystem`, `config_pet_suicong`, `com`, `refactory`).

To build and deploy an OTA hotpatch:
```powershell
python scripts/build_hotpatch.py
```
This updates `patch.zip` / `patch1.zip` in `web/wwwroot/127.0.0.1/res/` and bumps the patch version in `patch.meta.json`. On next client launch, players receive the update automatically. Incremental patches (`patch2.zip`, etc.) are also dynamically indexed by `version.php`.

---

## 🛡️ Port Forwarding Reference

| Port | Protocol | Service | Notes |
| :---: | :---: | :--- | :--- |
| **`80` / `33061`** | TCP | Web Gateway & OTA CDN | Reverse proxy for auth & patch downloads |
| **`81`** | TCP | Player Web Portal | Dashboard, Equipment Shop, GM tools |
| **`5556`** | TCP | Web API Gateway | Internal SceneServer socket delivery |
| **`7050`** | TCP | SuperServer | Cluster master coordinator |
| **`7080 - 7082`** | TCP | GateServers 1, 2, 3 | Client login & game gateway |
| **`6091` / `26091`** | TCP | Exchange (Trade Server) | Swoole daemon for player trading |
| **`14288` / `12053`** | TCP | Proxy Services | Mobile client scene proxies |
| **`3306`** | TCP | MySQL 5.7 Database | `ro_global` & `ro_xd_r2` |
| **`6379`** | TCP | Redis Cache | Session store |

---

## 📜 Credits & Acknowledgments

* **[LouLxGame](https://forum.ragezone.com/threads/ragnarok-m-ep5-vm-apk-pc-version-offline-new-mount-costume-2d-3d-camera-and-more-apk-support-android-14.1256253/)** — Creator of the enhanced Episode 5.0 server release, 64-bit Android APK, custom mounts, costumes, and 2D/3D camera mode.
* **[SkyArc](https://forum.ragezone.com/threads/ragnarok-m-english-patch-99-rom-mobile-korea-cn-2x-apk-vm-video-tutorial.1250510/)** — Creator of the core containerized Docker stack, English localization, Laravel web portal, and GM query socket integration.
* **RaGEZONE Community** — All developers and contributors who shared fixes, packet analysis, and tables.
