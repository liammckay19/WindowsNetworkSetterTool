This `README.md` is designed to be clear for you while remaining professional enough to show an IT auditor if they ever ask what the script does. It highlights the security features we added to ensure the script is viewed as a "utility" rather than a "vulnerability."

---

# Windows Network Setting Tool

A hardened PowerShell utility designed for switching between static IP profiles and DHCP on corporate-owned Windows assets. This tool prioritizes security, input validation, and auditability.

## 🛡️ Security Features

* **Zero System-Wide Footprint:** Does not require changing the system-wide `ExecutionPolicy`.
* **Privilege Guard:** Built-in check for Administrator rights (required for network stack modifications).
* **VPN Safety Guardrail:** Proactively detects active VPN tunnels and warns the user before modifying the physical NIC to prevent tunnel collapse.
* **Path Sanitization:** User-generated profile names are regex-sanitized to prevent path traversal or malicious file creation.
* **Type-Safe Input:** Uses `[ipaddress]` type accelerators to ensure inputs are valid IP addresses, preventing command injection.
* **Isolated Storage:** Configuration profiles are stored in the user's protected `%LOCALAPPDATA%` directory, not in the script folder.
* **Audit Logging:** Automatically starts a transcript for every session, logging all changes made for troubleshooting and compliance.

## 🚀 Usage

### 1. The "Zero-Trace" Launch
To run this on a restricted corporate machine without modifying global security settings, use the following command in a shortcut or a `.bat` file:

```batch
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "NetworkManager.ps1"
```

### 2. Manual Configuration
1. Select an active network adapter from the auto-detected list.
2. Choose **Manual Entry**.
3. Follow the prompts for IP, Subnet (supports CIDR like `24` or dotted-decimal like `255.255.255.0`), Gateway, and DNS.
4. Optionally save the profile for future use.

### 3. Loading Profiles
The script will automatically detect any saved `.ncfg` files in your local profile and present them as a numbered list at startup.

## 📁 File Locations

| Item | Path |
| :--- | :--- |
| **Log Files** | `%LOCALAPPDATA%\CorpNetTool\activity.log` |
| **Saved Profiles** | `%LOCALAPPDATA%\CorpNetTool\Configs\*.ncfg` |

## ⚠️ Requirements

* **OS:** Windows 10/11
* **Privileges:** Local Administrator
* **PowerShell:** 5.1 or Core

---
*Disclaimer: This tool is intended for professional use. Always ensure network changes comply with your corporate IT policy.*
