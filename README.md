## README: Windows Network Configuration Tool (GUI)

This repository contains a professional **PowerShell-based Graphical User Interface (GUI)** designed to simplify Windows network adapter management. It allows users to quickly switch between DHCP and Static IP configurations, save common profiles, and verify network changes in real-time.

---

### ## Key Features

* **Native Windows GUI:** Built using WinForms for a familiar, windowed experience—no command-line interaction required.
* **Self-Elevating Admin Rights:** Automatically detects if it’s running without privileges and prompts for "Run as Administrator."
* **Interface Auto-Detection:** Scans your system and populates a dropdown with only active ("Up") network adapters.
* **Security & Validation:** Uses **Regex validation** to ensure IP addresses, Subnet masks, and Gateways are formatted correctly before applying them.
* **Profile Management:** Save your most-used static configurations (e.g., "Office," "Lab," "Home") as `.ncfg` files for one-click loading.
* **Real-Time Logging:** Features a built-in terminal log that shows success messages, errors, and verification status.

---

### ## How It Works



The tool automates several complex PowerShell cmdlets (`Set-NetIPInterface`, `New-NetIPAddress`, and `Set-DnsClientServerAddress`) into a single "Apply" action. 

1.  **Selection:** Choose your adapter from the dropdown.
2.  **Configuration:** * Check **Use DHCP** to reset the adapter to automatic settings.
    * Uncheck it to manually enter **Static IP**, **Subnet** (supports `255.255.255.0` or CIDR `/24` formats), **Gateway**, and **DNS**.
3.  **Application:** Click **Apply Settings**. The tool clears existing static routes to prevent IP conflicts before assigning the new ones.
4.  **Verification:** The tool waits 2 seconds for the hardware to initialize and then verifies the assignment against the OS.

---

### ## Installation & Usage

1.  **Download:** Save the script as `NetSetGUI.ps1`.
2.  **Execution:** Right-click the file and select **Run with PowerShell**.
3.  **Profiles:** Saved profiles are stored in the same folder as the script with the `.ncfg` extension.

---

### ## Safety & Security

* **Validation:** Prevents "fat-finger" errors by checking IP octet ranges (0-255).
* **Clean Transitions:** When switching to Static IP, the script automatically removes the `0.0.0.0/0` destination prefix (Default Gateway) to ensure the new gateway becomes the primary route.
* **Non-Destructive:** Does not modify registry keys directly; it utilizes standard Microsoft Network Adapter modules.

---

### ## Requirements

* **OS:** Windows 10 or Windows 11.
* **Permissions:** Administrator privileges (the script will prompt for these).
* **Dependencies:** PowerShell 5.1 or higher (standard on modern Windows).

---

> **Note:** This tool is intended for network troubleshooting and administration. Ensure you have the correct network details before applying static settings to avoid losing connectivity.
