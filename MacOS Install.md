On macOS, browser policies are managed through .plist files instead of registry keys. Here are the manual steps for each browser:
1. Get your extension ID ready
You'll need your 32-character extension ID for all three.
2. Create the plist files
Open Terminal and run these commands:

Chrome:
# Force install
sudo defaults write /Library/Managed\ Preferences/com.google.Chrome ExtensionInstallForcelist -array-add "<EXTENSION_ID>;https://github.com/joshua-fitzgerald/SFDC-Extension/raw/main/updates.xml"

# Allowlist
sudo defaults write /Library/Managed\ Preferences/com.google.Chrome ExtensionInstallAllowlist -array-add "<EXTENSION_ID>"

Edge:
# Force install
sudo defaults write /Library/Managed\ Preferences/com.microsoft.Edge ExtensionInstallForcelist -array-add "<EXTENSION_ID>;https://github.com/joshua-fitzgerald/SFDC-Extension/raw/main/updates.xml"

# Allowlist
sudo defaults write /Library/Managed\ Preferences/com.microsoft.Edge ExtensionInstallAllowlist -array-add "<EXTENSION_ID>"

Brave:
# Force install
sudo defaults write /Library/Managed\ Preferences/com.brave.Browser ExtensionInstallForcelist -array-add "<EXTENSION_ID>;https://github.com/joshua-fitzgerald/SFDC-Extension/raw/main/updates.xml"

# Allowlist
sudo defaults write /Library/Managed\ Preferences/com.brave.Browser ExtensionInstallAllowlist -array-add "<EXTENSION_ID>"
3. Restart the browsers
Close and reopen each browser. The extension should install silently.
4. Verify
Go to chrome://policy, edge://policy, or brave://policy and click "Reload policies" — you should see the ExtensionInstallForcelist and ExtensionInstallAllowlist entries.

To Remove:
# Chrome
sudo defaults delete /Library/Managed\ Preferences/com.google.Chrome ExtensionInstallForcelist
sudo defaults delete /Library/Managed\ Preferences/com.google.Chrome ExtensionInstallAllowlist

# Edge
sudo defaults delete /Library/Managed\ Preferences/com.microsoft.Edge ExtensionInstallForcelist
sudo defaults delete /Library/Managed\ Preferences/com.microsoft.Edge ExtensionInstallAllowlist

# Brave
sudo defaults delete /Library/Managed\ Preferences/com.brave.Browser ExtensionInstallForcelist
sudo defaults delete /Library/Managed\ Preferences/com.brave.Browser ExtensionInstallAllowlist
