# 🌐 Mobile Client Networking: Microsoft Loopback Adapter Guide

This guide explains how to configure network connectivity for **Ragnarok M: Eternal Love (EP 5.0)** without requiring VMware Workstation.

---

## 💡 Why Is an Adapter Needed?

The LouLx mobile game client (`ROM.apk`) and client Lua scripts are hardcoded to connect to server IP:
```
192.168.128.129
```

When running the server with Docker Desktop on Windows:
* Container ports (ports `80`, `81`, `7080-7082`, `7050`, `6091`, `14288`, `3306`) are bound to **`0.0.0.0`** (all host network interfaces).
* Whenever Windows owns the IP `192.168.128.129` on **any** network adapter, incoming packets destined for that IP are immediately recognized as local traffic and intercepted by Docker.
* **VMware Workstation is NOT required.**

---

## 🏆 Priority Choice: Microsoft KM-TEST Loopback Adapter

The **Microsoft KM-TEST Loopback Adapter** is a native, software-only virtual network device built into all modern versions of Windows (Windows 10, Windows 11, Windows Server).

### Advantages:
1. **Zero 3rd-Party Software**: 100% native to Windows—no VMware, VirtualBox, or extra drivers needed.
2. **Permanent Availability**: Does not disconnect when you switch Wi-Fi networks, unplug Ethernet cables, or use a laptop offline.
3. **Completely Isolated**: Operates strictly within the Windows host kernel. It does not broadcast onto physical network interfaces, meaning it will **never conflict with physical routers, switches, or 802.1Q VLAN setups**.

---

## 🚀 Setup Instructions

### Method A: Automated Setup via Script (Fastest)

An automated PowerShell script is included in this repository:

1. Right-click **PowerShell** and choose **Run as Administrator**.
2. Run the script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\setup_loopback.ps1
   ```
3. The script will:
   * Detect and resolve any duplicate IP conflicts (e.g. disabling stale `VMnet8` adapters).
   * Open the Hardware Wizard if the loopback adapter is not yet installed.
   * Rename the adapter cleanly to **`RO-Loopback`**.
   * Assign IPv4 `192.168.128.129 / 24` without a default gateway.
   * Perform an automated health check against the Docker web portal (`http://192.168.128.129:81`).

---

### Method B: Manual GUI Setup (Step-by-Step)

#### Step 1: Install the Loopback Adapter
1. Press <kbd>Win</kbd> + <kbd>R</kbd>, type **`hdwwiz.exe`**, and press **Enter**.
2. Click **Next**.
3. Select **"Install the hardware that I manually select from a list (Advanced)"** and click **Next**.
4. Scroll down, select **Network adapters**, and click **Next**.
5. In the **Manufacturer** column on the left, select **Microsoft**.
6. In the **Model** column on the right, select **Microsoft KM-TEST Loopback Adapter**.
7. Click **Next** $\rightarrow$ **Next** $\rightarrow$ **Finish**.

#### Step 2: Assign the Static IP
1. Press <kbd>Win</kbd> + <kbd>R</kbd>, type **`ncpa.cpl`** (Network Connections), and press **Enter**.
2. Find the newly created adapter (typically named *Ethernet 2* or *Local Area Connection*).
   *(Tip: You can rename it to `RO-Loopback` for easy identification).*
3. Right-click the adapter $\rightarrow$ click **Properties**.
4. Double-click **Internet Protocol Version 4 (TCP/IPv4)**.
5. Configure the following values:
   * Select: **Use the following IP address**
   * **IP address:** `192.168.128.129`
   * **Subnet mask:** `255.255.255.0`
   * **Default gateway:** *(Leave blank)*
   * **DNS servers:** *(Leave blank)*
6. Click **OK** on both dialog windows.

---

## 🔍 Verification & Health Check

You can verify that the adapter and Docker are communicating properly without even opening the game client:

### 1. In Your Web Browser
Open your browser and navigate to:
```
http://192.168.128.129:81
```
The Ragnarok M Player Portal / Equipment Shop should load immediately.

### 2. In PowerShell / Terminal
```powershell
curl.exe -I http://192.168.128.129:81
```
Expected output:
```http
HTTP/1.1 200 OK
Server: nginx
X-Powered-By: PHP/8.2.35
```

---

## 🔄 Alternative Setup Options

| Option | Ideal For | Configuration |
| :--- | :--- | :--- |
| **Microsoft KM-TEST Loopback** *(Recommended)* | General use, laptops, clean setups | See steps above |
| **VMware VMnet8** | Users who already have VMware Workstation | In `ncpa.cpl`, set `VMware Network Adapter VMnet8` IPv4 to `192.168.128.129` / `255.255.255.0` |
| **Hyper-V Internal Switch** | Users already running Hyper-V / WSL2 switches | In Admin PowerShell:<br>`New-VMSwitch -Name "RO-Internal" -SwitchType Internal`<br>`New-NetIPAddress -InterfaceAlias "vEthernet (RO-Internal)" -IPAddress 192.168.128.129 -PrefixLength 24` |
| **Secondary IP on Existing NIC** | Advanced users who want zero extra adapters | In Admin PowerShell:<br>`New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.128.129 -PrefixLength 24` |

---

## 🛠️ Troubleshooting

### 1. "IP address already assigned" or Conflict Warning
If you previously had VMware installed, **VMware Network Adapter VMnet8** might still be holding `192.168.128.129`.
* Fix: Open `ncpa.cpl`, right-click **VMware Network Adapter VMnet8**, and select **Disable**.

### 2. Mobile Emulator (LDPlayer 9 / MuMu Player) Cannot Connect
* Make sure your emulator network mode is set to **NAT** or **Default**.
* In LDPlayer: Settings $\rightarrow$ Network $\rightarrow$ Network Bridging: **Disabled** (NAT mode routes through the Windows host network stack, allowing it to reach `192.168.128.129` seamlessly).

### 3. Remote Play Over Tailscale
If you are playing from a physical Android phone or remote laptop over Tailscale:
1. In Windows PowerShell:
   ```powershell
   tailscale up --advertise-routes=192.168.128.0/24
   ```
2. In your [Tailscale Admin Console](https://login.tailscale.com/admin/machines), locate your Windows host machine $\rightarrow$ **Edit route settings** $\rightarrow$ Approve `192.168.128.0/24`.
3. Your mobile phone connected to Tailscale can now reach `192.168.128.129` directly.
