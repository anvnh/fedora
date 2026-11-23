# Running Epic Seven on Linux (Steam / Proton)

This guide resolves the `STOVE ERROR` (`Cmd:STOVE_INITIALIZE Code:-80`) encountered at the server selection screen when running the Steam version of **Epic Seven** on Linux.

## Root Cause

The STOVE SDK relies on the **Microsoft Edge WebView2 Runtime** to initialize authentication sessions. Default Steam Proton prefixes do not include WebView2, causing `STOVE_INITIALIZE` to fail even when network connectivity is working.

## Tested Environment

- **OS:** Fedora Linux (native Steam installed via `dnf`)
- **Steam AppID:** `5019180`
- **Compatibility Tool:** Latest Proton / Proton Experimental / GE-Proton

## Prerequisites

- Epic Seven installed via Steam.
- `curl` installed on the host system.
- The game must be launched at least once to initialize its Proton prefix.

## Setup Steps

### 1. Select the Latest Proton Version

1. Open Steam, right-click **Epic Seven**, and select **Properties**.
2. Go to **Compatibility** and enable **Force the use of a specific Steam Play compatibility tool**.
3. Select the latest available Proton version (e.g., **Proton Experimental** or the latest **GE-Proton**).
4. Launch the game once so Steam downloads the selected Proton runtime and initializes the prefix, then close the game completely.

### 2. Install `protontricks` and Confirm the AppID

Install `protontricks` to execute Windows installers inside the exact Proton environment used by Steam (avoid invoking system `wine` directly, as version mismatches can corrupt the prefix):

```bash
sudo dnf install -y protontricks
```

List recognized Steam games to confirm the AppID:

```bash
protontricks -l
```

Verify that `Epic Seven (5019180)` appears in the output.

### 3. Download WebView2 Evergreen Standalone Installer (x64)

Download the offline **Evergreen Standalone x64** installer. Do not use the small (~1-2 MB) online bootstrapper, as it frequently hangs under Wine/Proton.

```bash
mkdir -p ~/Downloads
curl -fL -o ~/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64.exe "[https://go.microsoft.com/fwlink/?linkid=2124701](https://go.microsoft.com/fwlink/?linkid=2124701)"
```

Verify the downloaded file size (expected range: ~150-250 MB):

```bash
ls -lh ~/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64.exe
```

### 4. Install WebView2 into the Epic Seven Prefix

Ensure Epic Seven is completely closed, then run the silent installation inside AppID `5019180`:

```bash
protontricks-launch --appid 5019180 ~/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64.exe /silent /install
```

Wait 30-60 seconds for the process to exit. `fixme:` and `err:combase:` messages in the terminal output are expected under Wine/Proton and do not indicate installation failure.

### 5. Verify the Installation

Confirm that the WebView2 runtime directory exists inside the Proton prefix:

```bash
protontricks -c 'ls -la "$WINEPREFIX/drive_c/Program Files (x86)/Microsoft/EdgeWebView/Application/"' 5019180
```

A successful installation lists a versioned directory (for example, `158.0.4370.33`).

### 6. Launch Epic Seven

Start Epic Seven normally through Steam and proceed past the server selection screen.

## Notes and Caveats

- **Prefix Resets:** Uninstalling the game or deleting `compatdata/5019180` removes the installed WebView2 runtime. Re-run Steps 4-5 if the prefix is recreated.
- **Steam Flatpak:** If using the Flatpak version of Steam instead of a native package, install `com.github.Matoking.protontricks` from Flathub and ensure Flatpak has filesystem access to the directory containing the installer `.exe`.
- **Upstream Breakage:** Smilegate does not officially support Linux for the STOVE PC client. Future STOVE SDK or anti-cheat updates may break compatibility regardless of the WebView2 setup.