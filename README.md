# 🌐 Windows Network Config Tool (NetSet)

A lightweight PowerShell utility to swap between **DHCP** and **Static IP** configurations instantly. This tool allows you to save network profiles (home, office, lab) as files and apply them to any network interface with a single command.

---

## ✨ Features
* **DHCP & Static Support:** Easily toggle between automatic assignment and manual settings.
* **Profile Management:** Save your settings as `.ncfg` files for quick loading later.
* **Automatic Cleanup:** Automatically flushes old gateways and routes to prevent "Instance already exists" errors.
* **Portability:** Configuration files are stored in the same folder as the script (`$PSScriptRoot`).
* **Verification:** Automatically runs `ipconfig` after changes to confirm the new settings are active.

---

## 🚀 Quick Start

### 1. Requirements
* **Windows 10 or 11.**
* **Administrator Privileges** (required to modify hardware network settings).
* **PowerShell Execution Policy:** You must allow scripts to run. Open PowerShell as Admin and run:
    ```powershell
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```

### 2. Installation
1.  Copy the script code and save it as `NetSet.ps1`.
2.  Place it in a folder where you want to store your network profiles (e.g., `C:\Tools\Network\`).

### 3. Usage
1.  **Right-click** `NetSet.ps1` and select **Run with PowerShell** (ensure you are an Admin).
2.  **To Load:** Select a saved profile from the list (1, 2, 3...).
3.  **To Create New:** Select the **Manual Entry** option.
    * Choose your interface (e.g., `Ethernet 3`).
    * Choose `y` for **DHCP** or `n` for **Static**.
    * If Static, enter your IP, Mask, Gateway, and DNS.
4.  **Save:** Choose `y` when prompted to save the configuration for future use.

---

## 🛠 Desktop Shortcut (Recommended)
To run this tool quickly from your desktop with Admin rights:
1.  **Right-click** Desktop > **New** > **Shortcut**.
2.  **Target:** `powershell.exe -ExecutionPolicy Bypass -File "C:\Path\To\Your\NetSet.ps1"`
3.  **Name:** `Network Switcher`.
4.  **Admin Rights:** Right-click the new shortcut > **Properties** > **Advanced** > Check **Run as administrator**.

---

## 📂 Configuration Format
Profiles are saved as `.ncfg` files in the script directory. You can edit them manually in Notepad:

```ini
DHCP=False
IP=10.0.114.240
Mask=255.255.252.0
Gateway=10.0.112.1
DNS=8.8.8.8, 1.1.1.1
```

---

## ⚠️ Troubleshooting
* **"Admin" Warning:** If the script exits immediately, ensure you are right-clicking the shortcut/file and selecting **Run as Administrator**.
* **NIC Not Found:** Ensure you type the interface name exactly as it appears in the table (e.g., `Ethernet 3` including the space).
* **OneDrive Sync:** If your script is in a OneDrive folder, ensure the folder is "Always keep on this device" to prevent sync delays when reading config files.
