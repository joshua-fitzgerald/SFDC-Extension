<#
.SYNOPSIS
    Datto RMM Component - Remove Salesforce Admin Manager from Chrome, Edge & Brave
.DESCRIPTION
    Removes the extension from ExtensionInstallForcelist for all targeted browsers.
    The browser will uninstall the extension on next launch.

.NOTES
    Deploy as a Datto RMM Component (PowerShell, Run As: System)
    
    VARIABLES:
    - ExtensionID: Your 32-character extension ID
    - Browsers:    (Optional) Comma-separated: Chrome,Edge,Brave
#>

# ============================================================
# CONFIGURATION
# ============================================================
$ExtensionID = if ($env:ExtensionID) { $env:ExtensionID } else { "YOUR_32_CHARACTER_EXTENSION_ID" }
$BrowserList = if ($env:Browsers)    { $env:Browsers }    else { "Chrome,Edge,Brave" }

if ($ExtensionID -eq "YOUR_32_CHARACTER_EXTENSION_ID" -or $ExtensionID.Length -ne 32) {
    Write-Host "ERROR: ExtensionID is not set or invalid."
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

$TargetBrowsers = $BrowserList -split ',' | ForEach-Object { $_.Trim() }

# ============================================================
# HELPER FUNCTION
# ============================================================
function Remove-PolicyEntries {
    param(
        [string]$PolicyPath,
        [string]$MatchPattern,
        [string]$Label
    )

    if (-not (Test-Path $PolicyPath)) { return $false }

    $existing = Get-ItemProperty -Path $PolicyPath -ErrorAction SilentlyContinue
    $removed = $false

    if ($existing) {
        $properties = $existing.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' }
        foreach ($prop in $properties) {
            if ($prop.Value -like $MatchPattern) {
                Remove-ItemProperty -Path $PolicyPath -Name $prop.Name -Force
                Write-Host "  Removed $Label entry ($($prop.Name)): $($prop.Value)"
                $removed = $true
            }
        }
    }

    return $removed
}

# ============================================================
# REMOVE FROM EACH BROWSER
# ============================================================
Write-Host "=== Salesforce Admin Manager - Extension Removal ==="
Write-Host "Extension ID : $ExtensionID"
Write-Host "Browsers     : $($TargetBrowsers -join ', ')"
Write-Host ""

$totalRemoved = 0

foreach ($browser in $TargetBrowsers) {
    if (-not $BrowserPaths.ContainsKey($browser)) {
        Write-Host "[$browser] SKIPPED - unknown browser name"
        continue
    }

    $paths = $BrowserPaths[$browser]
    Write-Host "[$browser]"

    $removedForce = Remove-PolicyEntries -PolicyPath $paths.Forcelist -MatchPattern "${ExtensionID};*" -Label "forcelist"
    $removedAllow = Remove-PolicyEntries -PolicyPath $paths.Allowlist -MatchPattern $ExtensionID -Label "allowlist"

    if (-not $removedForce -and -not $removedAllow) {
        Write-Host "  No entries found"
    } else {
        $totalRemoved++
    }
    Write-Host ""
}

if ($totalRemoved -gt 0) {
    Write-Host "SUCCESS: Extension will be removed on next browser restart ($totalRemoved browser(s) cleaned)."
} else {
    Write-Host "No entries found in any browser. Nothing to remove."
}
exit 0
