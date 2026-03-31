# Ensure the script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run this script as an Administrator!"
    Pause
    exit
}

# --- Configuration Storage Settings ---
$ConfigDir = $PSScriptRoot
$ConfigExt = ".ncfg"

# Create the directory if it doesn't exist
if (-not (Test-Path $ConfigDir)) {
    New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
}

function Apply-Settings {
    param($NIC, $IsDHCP, $IP, $Mask, $Gateway, $DNS)

    Write-Host "`n--- Applying Settings to $NIC ---" -ForegroundColor Cyan
    
    if ($IsDHCP -eq "True") {
        try {
            Write-Host "Enabling DHCP for IP and DNS..." -ForegroundColor Yellow
            # Enable DHCP for IP
            Set-NetIPInterface -InterfaceAlias $NIC -Dhcp Enabled -ErrorAction Stop
            # Reset DNS to get from DHCP
            Set-DnsClientServerAddress -InterfaceAlias $NIC -ResetServerAddresses -ErrorAction Stop
            
            Write-Host "DHCP Enabled. Waiting for configuration..." -ForegroundColor Gray
            Start-Sleep -Seconds 3
        } catch {
            Write-Host "ERROR: Could not enable DHCP. $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        # --- Static Configuration Logic ---
        
        # 1. Remove existing static IPs and the Default Gateway
        Remove-NetIPAddress -InterfaceAlias $NIC -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $NIC -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
        
        # 2. Handle Subnet Mask conversion
        if ($Mask -like "*.*") {
            $Octets = $Mask.Split('.')
            $BinString = ""
            foreach ($Octet in $Octets) {
                $BinString += [Convert]::ToString([int]$Octet, 2).PadLeft(8, '0')
            }
            $Prefix = ($BinString.Replace('0', '')).Length
        } else {
            $Prefix = $Mask
        }

        # 3. Apply IP and Gateway
        try {
            if ($Gateway) {
                New-NetIPAddress -InterfaceAlias $NIC -IPAddress $IP -PrefixLength $Prefix -DefaultGateway $Gateway -ErrorAction Stop
            } else {
                New-NetIPAddress -InterfaceAlias $NIC -IPAddress $IP -PrefixLength $Prefix -ErrorAction Stop
            }

            # 4. Apply DNS
            if ($DNS) {
                $DNSArray = $DNS -split ',' | ForEach-Object { $_.Trim() }
                Set-DnsClientServerAddress -InterfaceAlias $NIC -ServerAddresses $DNSArray -ErrorAction Stop
            }
        } catch {
            Write-Host "ERROR: Could not apply static settings. $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }

    Write-Host "Verifying with ipconfig..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    
    # Verification logic
    if ($IsDHCP -eq "True") {
        # Check if DHCP is enabled on the interface
        $check = Get-NetIPInterface -InterfaceAlias $NIC -AddressFamily IPv4
        if ($check.Dhcp -eq 'Enabled') {
            Write-Host "SUCCESS: Interface is now in DHCP mode." -ForegroundColor Green
            ipconfig /all | Select-String -Pattern "IPv4 Address", "Subnet Mask", "Default Gateway", "DNS Servers" -Context 0,4
            return $true
        }
    } else {
        # Check if specific Static IP is present
        if (ipconfig /all | Select-String -Pattern $IP) {
            Write-Host "SUCCESS: Static IP $IP verified." -ForegroundColor Green
            return $true
        }
    }

    Write-Host "ERROR: Verification failed." -ForegroundColor Red
    return $false
}

# --- Main Logic ---

$Configs = Get-ChildItem -Path $ConfigDir -Filter "*$ConfigExt"
$ConfigCount = $Configs.Count

Write-Host "Windows Network Configuration Tool" -ForegroundColor Magenta
Write-Host "------------------------------------"

if ($ConfigCount -gt 0) {
    Write-Host "Found $ConfigCount saved configurations:"
    for ($i = 0; $i -lt $ConfigCount; $i++) {
        Write-Host "$($i + 1). $($Configs[$i].BaseName)"
    }
    Write-Host "$($ConfigCount + 1). Manual Entry (New Config)"
    
    $Choice = Read-Host "Choose an option (1-$($ConfigCount + 1))"

    if ($Choice -match '^\d+$' -and [int]$Choice -le $ConfigCount) {
        $SelectedFile = $Configs[[int]$Choice - 1].FullName
        $Data = Get-Content $SelectedFile | ConvertFrom-StringData
        
        $DHCP = $Data.DHCP
        $IP = $Data.IP
        $Mask = $Data.Mask
        $Gateway = $Data.Gateway
        $DNS = $Data.DNS

        Write-Host "`nLoaded Config: [DHCP=$DHCP] [IP=$IP] [Mask=$Mask]"
        Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object Name, Status, LinkSpeed | Format-Table
        $NIC = Read-Host "Enter the Interface Name to use"
        
        Apply-Settings -NIC $NIC -IsDHCP $DHCP -IP $IP -Mask $Mask -Gateway $Gateway -DNS $DNS
        Pause
        exit
    }
}

# --- Manual Entry Path ---
Get-NetAdapter | Select-Object Name, Status, LinkSpeed | Format-Table
$NIC = Read-Host "Enter the Interface Name (e.g., Ethernet 3)"

$DhcpInput = Read-Host "Use DHCP? (y/n)"
if ($DhcpInput -eq "y") {
    $DHCP = "True"
    $IP = $Mask = $Gateway = $DNS = ""
} else {
    $DHCP = "False"
    $IP = Read-Host "Enter the new IP address"
    $Mask = Read-Host "Enter the Subnet Mask (e.g., 255.255.255.0 or 24)"
    $Gateway = Read-Host "Enter the Gateway (optional - press Enter to skip)"
    $DNS = Read-Host "Enter DNS (e.g., 8.8.8.8, 1.1.1.1) (optional)"
}

if (Apply-Settings -NIC $NIC -IsDHCP $DHCP -IP $IP -Mask $Mask -Gateway $Gateway -DNS $DNS) {
    $Confirm = Read-Host "Would you like to save this configuration? (y/n)"
    if ($Confirm -eq "y") {
        $FileName = Read-Host "Enter a name for this config file"
        $ConfigContent = "DHCP=$DHCP`nIP=$IP`nMask=$Mask`nGateway=$Gateway`nDNS=$DNS"
        $SavePath = Join-Path $ConfigDir "$FileName$ConfigExt"
        $ConfigContent | Out-File -FilePath $SavePath -Encoding utf8
        Write-Host "Configuration saved to: $SavePath" -ForegroundColor Green
    }
}

Pause