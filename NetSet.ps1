<#
.SYNOPSIS
    Hardened Network Configuration Tool for Corporate Environments.
    Requires Administrator Privileges.
#>

# 1. Strict Admin Check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Access Denied. Please relaunch PowerShell as an Administrator."
    Pause; exit
}

# 2. Secure Environment Setup
# Store configs in the user's protected local app data instead of the script folder
$ConfigDir = Join-Path $env:LOCALAPPDATA "CorpNetTool\Configs"
if (-not (Test-Path $ConfigDir)) { 
    New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null 
}

$ConfigExt = ".ncfg"
$LogPath = Join-Path $env:LOCALAPPDATA "CorpNetTool\activity.log"

# Start Audit Logging
Start-Transcript -Path $LogPath -Append -Confirm:$false | Out-Null

function Apply-Settings {
    param(
        [Parameter(Mandatory)][string]$NIC,
        [Parameter(Mandatory)][bool]$IsDHCP,
        [ipaddress]$IP,
        [string]$Mask,
        [ipaddress]$Gateway,
        [ipaddress[]]$DNS
    )

    Write-Host "`n[!] Initializing Configuration for: $NIC" -ForegroundColor Cyan

    # Safety: Check for active VPN
    $VPN = Get-NetAdapter | Where-Object { ($_.InterfaceDescription -match "VPN" -or $_.Name -match "VPN") -and $_.Status -eq "Up" }
    if ($VPN) {
        Write-Warning "Active VPN detected ($($VPN.Name)). Changing settings now may disconnect you."
        $Continue = Read-Host "Proceed anyway? (y/N)"
        if ($Continue -ne "y") { return $false }
    }

    try {
        if ($IsDHCP) {
            Set-NetIPInterface -InterfaceAlias $NIC -Dhcp Enabled -ErrorAction Stop
            Set-DnsClientServerAddress -InterfaceAlias $NIC -ResetServerAddresses -ErrorAction Stop
        } else {
            # Robust Clean-up
            Remove-NetIPAddress -InterfaceAlias $NIC -Confirm:$false -ErrorAction SilentlyContinue
            Remove-NetRoute -InterfaceAlias $NIC -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue

            # Prefix Calculation (Hardened)
            if ($Mask -contains ".") {
                $bits = 0
                foreach ($octet in $Mask.Split('.')) {
                    $bits += ([System.Convert]::ToString([int]$octet, 2).ToCharArray() | Where-Object { $_ -eq '1' }).Count
                }
                $Prefix = $bits
            } else { $Prefix = [int]$Mask }

            $Params = @{
                InterfaceAlias = $NIC
                IPAddress      = $IP.IPAddressToString
                PrefixLength   = $Prefix
                ErrorAction    = "Stop"
            }
            if ($Gateway) { $Params.DefaultGateway = $Gateway.IPAddressToString }

            New-NetIPAddress @Params | Out-Null

            if ($DNS) {
                Set-DnsClientServerAddress -InterfaceAlias $NIC -ServerAddresses ($DNS | ForEach-Object { $_.IPAddressToString }) -ErrorAction Stop
            }
        }
        Write-Host "SUCCESS: Settings applied to $NIC" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Failed to apply settings: $($_.Exception.Message)"
        return $false
    }
}

# --- Main Logic ---
Write-Host "--- Corporate Network Manager (Secure Mode) ---" -ForegroundColor Magenta

# Selection Logic (Whitelisted Adapters Only)
$ValidAdapters = Get-NetAdapter | Where-Object { $_.Status -ne "Disconnected" }
$ValidAdapters | Select-Object Name, Status, LinkSpeed | Format-Table

$Selection = Read-Host "Enter the Interface Name exactly as shown above"
if ($Selection -notin $ValidAdapters.Name) {
    Write-Error "Invalid Interface Selection."
    exit
}

$Configs = Get-ChildItem -Path $ConfigDir -Filter "*$ConfigExt"
if ($Configs.Count -gt 0) {
    Write-Host "Available Profiles:"
    for ($i=0; $i -lt $Configs.Count; $i++) { Write-Host "$($i+1). $($Configs[$i].BaseName)" }
    $Choice = Read-Host "Select Profile # (or press Enter for Manual)"
    
    if ($Choice -match '^\d+$' -and [int]$Choice -le $Configs.Count) {
        $Data = Get-Content $Configs[[int]$Choice -1].FullName | ConvertFrom-StringData
        Apply-Settings -NIC $Selection -IsDHCP ([bool]::Parse($Data.DHCP)) `
                       -IP $Data.IP -Mask $Data.Mask -Gateway $Data.Gateway -DNS $Data.DNS
        Stop-Transcript; exit
    }
}

# Manual Entry with Validation
$isDHCPInput = (Read-Host "Use DHCP? (y/n)") -eq 'y'
if (-not $isDHCPInput) {
    [ipaddress]$userIP   = Read-Host "Enter IP Address (e.g. 192.168.1.50)"
    $userMask            = Read-Host "Enter Mask (e.g. 24 or 255.255.255.0)"
    [ipaddress]$userGW   = Read-Host "Enter Gateway (Optional)"
    $userDNS             = Read-Host "Enter DNS (Optional, comma separated)"
    
    if (Apply-Settings -NIC $Selection -IsDHCP $false -IP $userIP -Mask $userMask -Gateway $userGW -DNS $userDNS) {
        if ((Read-Host "Save profile? (y/n)") -eq 'y') {
            $SafeName = (Read-Host "Profile Name") -replace '[^a-zA-Z0-9]', ''
            $Content = "DHCP=False`nIP=$userIP`nMask=$userMask`nGateway=$userGW`nDNS=$userDNS"
            $Content | Out-File (Join-Path $ConfigDir "$SafeName$ConfigExt") -Encoding utf8
        }
    }
} else {
    Apply-Settings -NIC $Selection -IsDHCP $true
}

Stop-Transcript
