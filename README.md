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

### 3. Mobile Client Networking (VMnet8 & Tailscale)
The LouLx mobile client is configured to connect to IP **`192.168.128.129`**.

To connect smoothly:
1. On your Windows host, set the **VMware Network Adapter VMnet8** IPv4 address to:
   * **IP Address**: `192.168.128.129`
   * **Subnet Mask**: `255.255.255.0`
   * **Default Gateway**: *(Leave blank)*
2. Because Docker Desktop binds container ports to `0.0.0.0` on Windows, traffic sent to `192.168.128.129` is immediately intercepted by Docker without requiring a virtual machine.
3. **Tailscale Remote Play**: If playing over Tailscale from a remote phone or laptop, approve subnet route `192.168.128.0/24` in your Tailscale Admin Console.

### 4. Over-The-Air (OTA) Hotpatching Engine
* Modifying Lua client scripts no longer requires unpacking or recompiling the 2GB APK!
* The stack includes an automated AES-256-CBC bundle compiler:
  ```powershell
  python scripts/build_hotpatch.py
  ```
* Edits in `client/patch_lua/` are automatically encrypted into Unity TextAssets, repacked into `patch.zip` / `patch1.zip` under `web/wwwroot/127.0.0.1/res/`, and version-bumped in `patch.meta.json`.
* Players receive client patches over-the-air upon game launch.

### 5. Web Equipment Shop (Port 81)
* Web store at `http://localhost:81/equipment_shop` with **4,450+ items** cataloged.
* Instant background AJAX mail delivery (items arrive in player's in-game mailbox in 1 second without page reload).
* Dedicated tabs for **Weapons**, **Armors**, **Footgears**, **Mounts & Costumes (760 items)**, **Food & Consumables (Ultraman dishes, +15 refine vouchers)**, and **Cards (353 cards)** with slot sub-filters (Shoes, Off-hand, Accessories, Headwear, MVP).

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

### Step 4: Configure VMnet8 Network Adapter
1. Open Windows **Control Panel** $\rightarrow$ **Network Connections**.
2. Right-click **VMware Network Adapter VMnet8** $\rightarrow$ **Properties**.
3. Select **Internet Protocol Version 4 (TCP/IPv4)** $\rightarrow$ **Properties**:
   * Select: **Use the following IP address**
   * **IP address:** `192.168.128.129`
   * **Subnet mask:** `255.255.255.0`
   * **Default gateway:** *(leave blank)*
4. Click **OK**.

### Step 5: Start the Server Stack
Run the Windows startup script (which verifies WSL host mount and launches containers):
```powershell
.\start-server.ps1
```
*Or standard Docker Compose:*
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
- `MainViewTaskQuestPage.lua` & `QuestTraceCell.lua`: 0-load screen quest teleport.
- `UIViewControllerZenyShop.lua` & `UIListItemViewControllerZenyShopItem.lua`: Big Cat Store mock payment.
- `Table_MonthCard.lua`: 2026 month card crash fix.
- `FunctionMonster.lua`: VIP MVP & Mini-Boss map detection.

To build and deploy an OTA hotpatch:
```powershell
python scripts/build_hotpatch.py
```
This updates `patch.zip` / `patch1.zip` in `web/wwwroot/127.0.0.1/res/` and bumps the patch version in `patch.meta.json`. On next client launch, players receive the update automatically.

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
