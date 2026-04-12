<#
.SYNOPSIS
   Force-install Salesforce Admin Manager on Chrome, Edge & Brave
.DESCRIPTION
    Adds registry entries under ExtensionInstallForcelist for all targeted
    Chromium browsers to silently install the extension on next launch.
    No developer mode or user interaction required.
#>

# ============================================================
# CONFIGURATION
# ============================================================
$ExtensionID  = if ($env:ExtensionID)  { $env:ExtensionID }  else { "pcebaddpadiagolcncmeholgfeiegpgc" }
$UpdateXMLURL = if ($env:UpdateXMLURL) { $env:UpdateXMLURL } else { "https://github.com/joshua-fitzgerald/SFDC-Extension/raw/main/updates.xml" }
$BrowserList  = if ($env:Browsers)     { $env:Browsers }     else { "Chrome,Edge,Brave" }

# Validate
if ($ExtensionID -eq "YOUR_32_CHARACTER_EXTENSION_ID" -or $ExtensionID.Length -ne 32) {
    Write-Host "ERROR: ExtensionID is not set or invalid. Must be 32 characters."
    exit 1
}
if ([string]::IsNullOrWhiteSpace($UpdateXMLURL)) {
    Write-Host "ERROR: UpdateXMLURL is not set."
    exit 1
}

# ============================================================
# BROWSER REGISTRY PATHS
# ============================================================
$BrowserPaths = @{
    Chrome = @{
        Forcelist = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
        Allowlist = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist"
    }
    Edge = @{
        Forcelist = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"
        Allowlist = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallAllowlist"
    }
    Brave = @{
        Forcelist = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave-Browser\ExtensionInstallForcelist"
        Allowlist = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave-Browser\ExtensionInstallAllowlist"
    }
}

$ForcelistValue = "${ExtensionID};${UpdateXMLURL}"
$TargetBrowsers = $BrowserList -split ',' | ForEach-Object { $_.Trim() }

# ============================================================
# HELPER FUNCTIONS
# ============================================================
function Add-ForcelistEntry {
    param(
        [string]$PolicyPath,
        [string]$Value,
        [string]$ExtId
    )

    if (-not (Test-Path $PolicyPath)) {
        New-Item -Path $PolicyPath -Force | Out-Null
        Write-Host "  Created registry key: $PolicyPath"
    }

    $existing = Get-ItemProperty -Path $PolicyPath -ErrorAction SilentlyContinue
    $alreadyInstalled = $false
    $nextIndex = 1

    if ($existing) {
        $properties = $existing.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' }
        foreach ($prop in $properties) {
            if ($prop.Value -like "${ExtId};*") {
                if ($prop.Value -ne $Value) {
                    Set-ItemProperty -Path $PolicyPath -Name $prop.Name -Value $Value
                    Write-Host "  Updated existing entry ($($prop.Name))"
                } else {
                    Write-Host "  Already configured correctly"
                }
                $alreadyInstalled = $true
                break
            }
            $idx = [int]$prop.Name
            if ($idx -ge $nextIndex) { $nextIndex = $idx + 1 }
        }
    }

    if (-not $alreadyInstalled) {
        Set-ItemProperty -Path $PolicyPath -Name $nextIndex.ToString() -Value $Value -Type String
        Write-Host "  Added forcelist entry ($nextIndex)"
    }
}

function Add-AllowlistEntry {
    param(
        [string]$AllowlistPath,
        [string]$ExtId
    )

    if (-not (Test-Path $AllowlistPath)) { return }

    $existing = Get-ItemProperty -Path $AllowlistPath -ErrorAction SilentlyContinue
    $alreadyAllowed = $false
    $nextIndex = 1

    if ($existing) {
        $properties = $existing.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' }
        foreach ($prop in $properties) {
            if ($prop.Value -eq $ExtId) {
                $alreadyAllowed = $true
                break
            }
            $idx = [int]$prop.Name
            if ($idx -ge $nextIndex) { $nextIndex = $idx + 1 }
        }
    }

    if (-not $alreadyAllowed) {
        Set-ItemProperty -Path $AllowlistPath -Name $nextIndex.ToString() -Value $ExtId -Type String
        Write-Host "  Added to allowlist ($nextIndex)"
    }
}

# ============================================================
# INSTALL FOR EACH BROWSER
# ============================================================
Write-Host "=== Salesforce Admin Manager - Extension Force-Install ==="
Write-Host "Extension ID : $ExtensionID"
Write-Host "Update URL   : $UpdateXMLURL"
Write-Host "Browsers     : $($TargetBrowsers -join ', ')"
Write-Host ""

$successCount = 0

foreach ($browser in $TargetBrowsers) {
    if (-not $BrowserPaths.ContainsKey($browser)) {
        Write-Host "[$browser] SKIPPED - unknown browser name"
        continue
    }

    $paths = $BrowserPaths[$browser]
    Write-Host "[$browser]"

    Add-ForcelistEntry -PolicyPath $paths.Forcelist -Value $ForcelistValue -ExtId $ExtensionID
    Add-AllowlistEntry -AllowlistPath $paths.Allowlist -ExtId $ExtensionID

    $successCount++
    Write-Host ""
}

# ============================================================
# VERIFICATION
# ============================================================
Write-Host "=== Verification ==="
foreach ($browser in $TargetBrowsers) {
    if (-not $BrowserPaths.ContainsKey($browser)) { continue }
    $paths = $BrowserPaths[$browser]
    if (Test-Path $paths.Forcelist) {
        $verify = Get-ItemProperty -Path $paths.Forcelist -ErrorAction SilentlyContinue
        $entries = $verify.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' }
        foreach ($prop in $entries) {
            if ($prop.Value -like "${ExtensionID};*") {
                Write-Host "  [$browser] OK - $($prop.Value)"
            }
        }
    }
}

Write-Host ""
if ($successCount -gt 0) {
    Write-Host "SUCCESS: Extension will install on next browser launch ($successCount browser(s) configured)."
    exit 0
} else {
    Write-Host "WARNING: No browsers were configured."
    exit 1
}
