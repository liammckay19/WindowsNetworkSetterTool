This **README** is designed to help you (or anyone else) set up and use the script quickly. You can save this text as a file named `README.md` in the same folder as your script.

---

# 🌐 Windows Network Configuration Tool (NetSet)

A lightweight, interactive PowerShell utility designed to quickly change network interface settings. It allows you to set static IPs, subnet masks, gateways, and DNS servers, with the added ability to save and load these profiles for future use.

## ✨ Features
* **Profile Management:** Save frequently used network settings to `.ncfg` files.
* **Smart Loading:** Automatically detects configuration files in the current directory and lists them in a menu.
* **DNS Support:** Configure primary and secondary DNS servers easily.
* **Gateway Cleanup:** Automatically removes existing default gateways to prevent "Instance already exists" errors.
* **Compatibility:** Works on standard Windows PowerShell (5.1) and newer versions.
* **Verification:** Performs a live `ipconfig` check to ensure settings were applied successfully.

---

## 🚀 Getting Started

### 1. Prerequisites
* **Windows OS:** This script is designed for Windows 10/11.
* **Administrator Rights:** Network changes require elevated privileges.
* **Execution Policy:** You may need to allow scripts to run on your machine. Open PowerShell as Admin and run:
    ```powershell
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```

### 2. Installation
1.  Save the script as `NetSet.ps1` in a dedicated folder (e.g., `C:\Tools\Network\`).
2.  Any saved configurations will be created in this same folder with the `.ncfg` extension.

---

## 🛠 Usage

### Creating a Desktop Shortcut (Recommended)
To run the tool with one click:
1.  **Right-click** on your Desktop > **New** > **Shortcut**.
2.  In the location box, paste:
    `powershell.exe -ExecutionPolicy Bypass -File "C:\Path\To\Your\NetSet.ps1"`
    *(Replace the path with your actual file location)*.
3.  Name it **"Network Switcher"**.
4.  **Right-click** the new shortcut > **Properties** > **Advanced...**
5.  Check **"Run as administrator"** and click OK.

### Running the Script
1.  **Launch the script:** If saved configurations exist, you will see a list (1-N).
2.  **Manual Entry:** Choose the last option (Manual Entry) to type in new settings.
3.  **Applying:**
    * Select your **Interface Name** (e.g., `Ethernet 3` or `Wi-Fi`) from the provided list.
    * The script will flush the old settings and apply the new ones.
4.  **Saving:** If the application is successful, the script will ask if you want to save the profile. Give it a name like `HomeOffice` or `ClientSiteA`.

---

## 📂 Configuration Files
Configurations are stored as simple text files:
* **File Format:** `Name.ncfg`
* **Content Example:**
    ```text
    IP=10.0.114.240
    Mask=255.255.252.0
    Gateway=10.0.112.1
    DNS=8.8.8.8, 8.8.4.4
    ```

---

## ⚠️ Troubleshooting

### "Instance DefaultGateway already exists"
The script now includes a fix for this! It automatically runs `Remove-NetRoute` for the specific interface before adding a new gateway to clear out the old path.

### NIC Name Errors
If you get an error that the interface name isn't found, ensure you are typing the name exactly as it appears in the table (e.g., `Ethernet 3` is different than `Ethernet3`). 

---

**Note:** *This tool is intended for static IP management. To return to DHCP (Automatic IP), use the Windows Network Settings menu or run `Set-NetIPInterface -InterfaceAlias "YourNIC" -Dhcp Enabled`.*