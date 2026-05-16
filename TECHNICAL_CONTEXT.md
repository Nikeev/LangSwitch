# LangSwitch Technical Context

Date: 2026-05-16
Branch: hardening/security-ux

## Project Shape

LangSwitch is a small macOS SwiftUI/AppKit utility. Most runtime behavior lives in `LangSwitch/AppDelegate.swift`; `LangSwitch/LangSwitchApp.swift` only wires the application delegate into the SwiftUI app entry point.

The app:
- registers itself as a login item on launch with `SMAppService.mainApp.register()`;
- installs a global `.flagsChanged` event monitor for the Fn/globe key;
- switches keyboard input sources via Carbon TIS APIs;
- exposes a status bar menu with About, Hide Icon, and Exit;
- checks GitHub releases via `URLSession`.

## Review Commands Run

Potentially sensitive Swift/macOS APIs:

```sh
grep -RIn "SMAppService\|register()\|unregister()\|launchAtLogin\|addGlobalMonitor\|TISCreate\|TISGet\|TISSelect\|UserDefaults\|NSStatusBar\|isVisible\|activationPolicy" LangSwitch
```

Force unwrap / force cast search:

```sh
grep -RIn "as!\|try!\|!" LangSwitch --include="*.swift"
```

Network search:

```sh
grep -RIn "URLSession\|URLRequest\|https://\|http://" LangSwitch
```

Entitlements inspected:

```sh
cat LangSwitch/LangSwitch.entitlements
```

Hidden Unicode / bidi check:

```sh
python3 - <<'PY'
from pathlib import Path
bad = {
    "\u202A": "LRE",
    "\u202B": "RLE",
    "\u202C": "PDF",
    "\u202D": "LRO",
    "\u202E": "RLO",
    "\u2066": "LRI",
    "\u2067": "RLI",
    "\u2068": "FSI",
    "\u2069": "PDI",
}
for p in Path(".").rglob("*"):
    if p.is_file() and p.suffix in {".swift", ".md", ".plist", ".entitlements", ".pbxproj"}:
        try:
            text = p.read_text(errors="ignore")
        except Exception:
            continue
        for i, line in enumerate(text.splitlines(), 1):
            found = [(name, hex(ord(ch))) for ch, name in bad.items() if ch in line]
            if found:
                print(f"{p}:{i}: {found}")
PY
```

The bidi check produced no output.

## Notable Risk Points

- `LangSwitch/AppDelegate.swift:23` calls `launchAtLogin()` immediately on every application launch.
- `LangSwitch/AppDelegate.swift:50` registers `NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged)` without visible permission guidance or fallback behavior.
- `LangSwitch/AppDelegate.swift:114` calls `SMAppService.mainApp.register()` automatically when the login item is not enabled.
- `LangSwitch/AppDelegate.swift:146` compares versions lexicographically with `latestVersion > "v\(currentVersion)"`, which is unsafe for semantic versions.
- `LangSwitch/AppDelegate.swift:180` uses `takeUnretainedValue()` on `TISCopyCurrentKeyboardInputSource()`, even though the Copy rule indicates the caller owns the returned value.
- `LangSwitch/AppDelegate.swift:208` force-unwraps the localized-name pointer path through `Unmanaged.fromOpaque(...)` without a nil check.
- `LangSwitch/AppDelegate.swift:215`, `:248`, and `:252` contain force casts around TIS input source data.
- `LangSwitch/AppDelegate.swift:167` hides the status bar icon and persists that setting, but the UI provides no direct path to show it again.

## Entitlements

Current entitlements:

- `com.apple.security.app-sandbox`
- `com.apple.security.files.user-selected.read-only`
- `com.apple.security.network.client`

`network.client` is used by GitHub update checks. The read-only user-selected file entitlement is not obviously used by the current app code.

## Verification Limitations

`xcodebuild` could not run in this environment because the active developer directory is Command Line Tools, not a full Xcode installation.

`swiftc -typecheck` first failed because the sandbox blocked writes to the default clang module cache. A retry with a local module cache did not complete in a useful amount of time and was stopped.
