# 1. --- Security: Ensure Admin Rights & Self-Elevation ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell"
    $newProcess.Arguments = "& '$PSCommandPath'"
    $newProcess.Verb = "runas"
    try {
        [System.Diagnostics.Process]::Start($newProcess)
    } catch {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show("This tool requires Administrator privileges to change network settings.", "Admin Required", "OK", "Warning")
    }
    exit
}

# Load GUI assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Configuration Storage Settings ---
$ConfigDir = $PSScriptRoot
$ConfigExt = ".ncfg"

if (-not (Test-Path $ConfigDir)) {
    New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
}

# --- GUI Setup ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Secure Network Config Tool"
$Form.Size = New-Object System.Drawing.Size(500, 650)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false

$DefaultFont = New-Object System.Drawing.Font("Segoe UI", 9)
$Form.Font = $DefaultFont

function New-Label ($Text, $X, $Y) {
    $Label = New-Object System.Windows.Forms.Label
    $Label.Text = $Text
    $Label.Location = New-Object System.Drawing.Point($X, $Y)
    $Label.AutoSize = $true
    return $Label
}

# --- Controls ---
$Form.Controls.Add((New-Label "Select Network Interface:" 20 20))
$cmbAdapters = New-Object System.Windows.Forms.ComboBox
$cmbAdapters.Location = New-Object System.Drawing.Point(20, 40)
$cmbAdapters.Size = New-Object System.Drawing.Size(440, 25)
$cmbAdapters.DropDownStyle = "DropDownList"
$Form.Controls.Add($cmbAdapters)

$Form.Controls.Add((New-Label "Saved Configurations:" 20 75))
$lstConfigs = New-Object System.Windows.Forms.ListBox
$lstConfigs.Location = New-Object System.Drawing.Point(20, 95)
$lstConfigs.Size = New-Object System.Drawing.Size(440, 80)
$Form.Controls.Add($lstConfigs)

$chkDHCP = New-Object System.Windows.Forms.CheckBox
$chkDHCP.Text = "Use DHCP (Auto-assign IP and DNS)"
$chkDHCP.Location = New-Object System.Drawing.Point(20, 190)
$chkDHCP.Size = New-Object System.Drawing.Size(250, 25)
$Form.Controls.Add($chkDHCP)

$Form.Controls.Add((New-Label "IP Address:" 20 225))
$txtIP = New-Object System.Windows.Forms.TextBox
$txtIP.Location = New-Object System.Drawing.Point(120, 222)
$txtIP.Size = New-Object System.Drawing.Size(340, 25)
$Form.Controls.Add($txtIP)

$Form.Controls.Add((New-Label "Subnet Mask:" 20 255))
$txtMask = New-Object System.Windows.Forms.TextBox
$txtMask.Location = New-Object System.Drawing.Point(120, 252)
$txtMask.Size = New-Object System.Drawing.Size(340, 25)
$Form.Controls.Add($txtMask)

$Form.Controls.Add((New-Label "Gateway:" 20 285))
$txtGateway = New-Object System.Windows.Forms.TextBox
$txtGateway.Location = New-Object System.Drawing.Point(120, 282)
$txtGateway.Size = New-Object System.Drawing.Size(340, 25)
$Form.Controls.Add($txtGateway)

$Form.Controls.Add((New-Label "DNS Servers:" 20 315))
$txtDNS = New-Object System.Windows.Forms.TextBox
$txtDNS.Location = New-Object System.Drawing.Point(120, 312)
$txtDNS.Size = New-Object System.Drawing.Size(340, 25)
$Form.Controls.Add($txtDNS)

$btnApply = New-Object System.Windows.Forms.Button
$btnApply.Text = "Apply Settings"
$btnApply.Location = New-Object System.Drawing.Point(20, 355)
$btnApply.Size = New-Object System.Drawing.Size(120, 35)
$btnApply.BackColor = [System.Drawing.Color]::LightGreen
$Form.Controls.Add($btnApply)

$txtSaveName = New-Object System.Windows.Forms.TextBox
$txtSaveName.Location = New-Object System.Drawing.Point(160, 362)
$txtSaveName.Size = New-Object System.Drawing.Size(170, 25)
$txtSaveName.Text = "ProfileName"
$Form.Controls.Add($txtSaveName)

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "Save Config"
$btnSave.Location = New-Object System.Drawing.Point(340, 355)
$btnSave.Size = New-Object System.Drawing.Size(120, 35)
$btnSave.BackColor = [System.Drawing.Color]::LightBlue
$Form.Controls.Add($btnSave)

$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 410)
$txtLog.Size = New-Object System.Drawing.Size(440, 180)
$txtLog.ReadOnly = $true
$txtLog.BackColor = [System.Drawing.Color]::Black
$txtLog.ForeColor = [System.Drawing.Color]::LimeGreen
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$Form.Controls.Add($txtLog)

# --- Logic Functions ---

function Log-Message ($Msg, $Color = "LimeGreen") {
    $txtLog.SelectionStart = $txtLog.TextLength
    $txtLog.SelectionLength = 0
    $txtLog.SelectionColor = [System.Drawing.Color]::FromName($Color)
    $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $Msg`n")
    $txtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# Validation: Checks if a string is a valid IPv4
function Test-IsValidIP ($IP) {
    if ([string]::IsNullOrWhiteSpace($IP)) { return $false }
    return $IP -match '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
}

# Validation: Checks for valid subnet (255.x.x.x or CIDR /1-32)
function Test-IsValidSubnet ($Mask) {
    if ($Mask -match '^\d+$') { return ([int]$Mask -ge 1 -and [int]$Mask -le 32) }
    return Test-IsValidIP $Mask
}

function Refresh-Configs {
    $lstConfigs.Items.Clear()
    if (Test-Path $ConfigDir) {
        Get-ChildItem -Path $ConfigDir -Filter "*$ConfigExt" | ForEach-Object { $lstConfigs.Items.Add($_.BaseName) | Out-Null }
    }
}

# --- Event Handlers ---

$Form.Add_Load({
    Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object { $cmbAdapters.Items.Add($_.Name) | Out-Null }
    if ($cmbAdapters.Items.Count -gt 0) { $cmbAdapters.SelectedIndex = 0 }
    Refresh-Configs
})

$chkDHCP.Add_CheckedChanged({
    $State = -not $chkDHCP.Checked
    @($txtIP, $txtMask, $txtGateway, $txtDNS) | ForEach-Object { $_.Enabled = $State }
})

$lstConfigs.Add_SelectedIndexChanged({
    if ($lstConfigs.SelectedItem) {
        $Data = Get-Content (Join-Path $ConfigDir "$($lstConfigs.SelectedItem)$ConfigExt") | ConvertFrom-StringData
        $chkDHCP.Checked = ($Data.DHCP -eq "True")
        if (-not $chkDHCP.Checked) {
            $txtIP.Text = $Data.IP; $txtMask.Text = $Data.Mask; $txtGateway.Text = $Data.Gateway; $txtDNS.Text = $Data.DNS
        }
        Log-Message "Profile Loaded: $($lstConfigs.SelectedItem)"
    }
})

$btnSave.Add_Click({
    $Name = $txtSaveName.Text.Replace(" ", "_")
    if ([string]::IsNullOrWhiteSpace($Name)) { [System.Windows.Forms.MessageBox]::Show("Enter a profile name."); return }
    $Content = "DHCP=$($chkDHCP.Checked)`nIP=$($txtIP.Text)`nMask=$($txtMask.Text)`nGateway=$($txtGateway.Text)`nDNS=$($txtDNS.Text)"
    $Content | Out-File (Join-Path $ConfigDir "$Name$ConfigExt") -Encoding utf8
    Log-Message "Saved profile: $Name"
    Refresh-Configs
})

$btnApply.Add_Click({
    $NIC = $cmbAdapters.SelectedItem
    if (-not $NIC) { Log-Message "ERROR: No Interface." "Red"; return }

    $btnApply.Enabled = $false
    Log-Message "Applying settings to $NIC..."

    if ($chkDHCP.Checked) {
        try {
            Set-NetIPInterface -InterfaceAlias $NIC -Dhcp Enabled -ErrorAction Stop
            Set-DnsClientServerAddress -InterfaceAlias $NIC -ResetServerAddresses -ErrorAction Stop
            Log-Message "DHCP Enabled Successfully."
        } catch { Log-Message "DHCP Error: $($_.Exception.Message)" "Red" }
    } else {
        # 2. --- Security: Validate Input before executing Commands ---
        if (-not (Test-IsValidIP $txtIP.Text)) { Log-Message "Invalid IP Format!" "Red"; $btnApply.Enabled = $true; return }
        if (-not (Test-IsValidSubnet $txtMask.Text)) { Log-Message "Invalid Subnet/CIDR!" "Red"; $btnApply.Enabled = $true; return }

        try {
            # Clear old routes/IPs safely
            Remove-NetIPAddress -InterfaceAlias $NIC -Confirm:$false -ErrorAction SilentlyContinue
            Remove-NetRoute -InterfaceAlias $NIC -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue

            $Prefix = if ($txtMask.Text -like "*.*") { 
                $Octets = $txtMask.Text.Split('.'); $Bin = ""; foreach ($o in $Octets) { $Bin += [Convert]::ToString([int]$o, 2).PadLeft(8, '0') }; ($Bin.Replace('0', '')).Length 
            } else { $txtMask.Text }

            $Params = @{ InterfaceAlias = $NIC; IPAddress = $txtIP.Text; PrefixLength = $Prefix; ErrorAction = "Stop" }
            if ($txtGateway.Text -and (Test-IsValidIP $txtGateway.Text)) { $Params.DefaultGateway = $txtGateway.Text }
            
            New-NetIPAddress @Params | Out-Null
            
            if ($txtDNS.Text) {
                $DnsList = $txtDNS.Text -split ',' | ForEach-Object { $_.Trim() }
                Set-DnsClientServerAddress -InterfaceAlias $NIC -ServerAddresses $DnsList -ErrorAction Stop
            }
            Log-Message "Static IP Applied: $($txtIP.Text)"
        } catch { Log-Message "Error: $($_.Exception.Message)" "Red" }
    }
    $btnApply.Enabled = $true
})

$Form.ShowDialog() | Out-Null
