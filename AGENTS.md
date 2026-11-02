# LangSwitch

LangSwitch is a small native macOS menu bar utility. A short Fn/Globe key
press cycles through keyboard input sources without the system switcher's
popup or delay. Keep this single-purpose behavior fast and predictable.

## Project map

- `LangSwitch/LangSwitchApp.swift`: SwiftUI entry point; installs the AppKit
  application delegate and provides an empty Settings scene.
- `LangSwitch/AppDelegate.swift`: application lifecycle, menu bar and About
  window, Fn event monitoring, input-source switching, login registration,
  and the manual GitHub release check. The `TISInputSource` extension at the
  end of this file wraps Carbon input-source properties.
- `LangSwitch/LangSwitch.entitlements`: App Sandbox, outgoing network access
  for update checks, and user-selected read-only file access.
- `LangSwitch/Assets.xcassets`: app icon and color assets.
- `LangSwitch.xcodeproj/project.pbxproj`: targets, source membership, generated
  Info.plist settings, versions, deployment targets, and signing configuration.
- `README.md`: purpose and user setup instructions. `LICENSE`: MIT license.

There are no third-party dependencies or package manager setup steps. The app
uses SwiftUI, AppKit, Carbon, IOKit, and ServiceManagement.

## Current behavior

- Users must disable the built-in Fn/Globe action in macOS Keyboard settings,
  as described in the README.
- A global `NSEvent` monitor observes `flagsChanged` events for key code 63.
  Switching happens on release when the press lasts less than 0.2 seconds.
  Caps Lock is allowed; the handler also checks other modifier flags.
  Input-source selection can still turn Caps Lock off; the app currently does
  not restore its state (see GitHub issues #12 and #14).
- `switchKeyboardLanguage()` gets the current input source, finds it in the
  selectable keyboard sources returned by Carbon, and selects the next one
  with wraparound. This is sequential cycling, not last-used-source toggling.
- The app uses the accessory activation policy. Its menu offers About,
  Hide Icon, and Exit. Hiding the icon persists in the `hideStatusBarIcon`
  UserDefaults key. Reopening the running app restores the icon and clears
  that preference through `applicationShouldHandleReopen`.
- Startup automatically attempts login-item registration with
  `SMAppService.mainApp` on macOS 13 and later. Earlier systems only log that
  this feature is unavailable.
- Checking for updates is a manual About-window action. It requests the latest
  release from `https://api.github.com/repos/Nikeev/LangSwitch/releases/latest`.

These describe the checked-in implementation, not pending pull requests.
Update this file when an accepted change alters these behaviors.

## Build and validation

Use a full Xcode installation on macOS. Open `LangSwitch.xcodeproj` and select
the `LangSwitch` scheme. The project uses Swift 5 language mode. The app target
overrides the project deployment target to macOS 11; project-level and unit
test settings specify macOS 13.3. Guard newer APIs rather than silently raising
the app's minimum OS version.

For a build that does not require the maintainer's signing identity:

```sh
xcodebuild \
    -project LangSwitch.xcodeproj \
    -scheme LangSwitch \
    -configuration Debug \
    -destination 'platform=macOS' \
    -derivedDataPath /tmp/LangSwitch-DerivedData \
    CODE_SIGNING_ALLOWED=NO \
    build
```

If a newer Xcode rejects the macOS 11 deployment target, use a compatible older
Xcode to validate macOS 11 support. A command-line override such as
`MACOSX_DEPLOYMENT_TARGET=12.0` can check compilation with Xcode 27, but does not
validate the declared minimum OS version or change the project settings.

`LangSwitchTests` and `LangSwitchUITests` targets exist, but their Sources build
phases are empty and no test implementations are checked in. A successful build
does not prove keyboard-event behavior. For event-handling changes, manually
check short taps, long holds, rapid taps, Fn shortcuts with modifiers and arrow
keys, Caps Lock on/off, and cycling through two and three input sources. Check
sleep/wake for monitor changes and relaunch/login for startup or menu changes.
For icon visibility changes, check Hide Icon, reopen the running app, and
relaunch; the restored icon should stay visible until explicitly hidden again.
Report which checks actually ran and which require real hardware or permissions.

## Change guidelines

- Read the affected code and all callers before editing. Keep changes small
  and reuse the existing structure and native APIs.
- Use readable multiline Swift with the existing four-space indentation and
  brace placement. Expand `if`/`else`, loops, and `do`/`catch` into blocks with
  statements on separate lines. Wrap long argument lists, arrays, and compound
  conditions. Do not compress code at the expense of readability.
- Preserve Fn shortcuts, Caps Lock behavior, sandboxing, and the absence of
  a switching popup. Changes to event interception or permission requirements
  need explicit validation and matching README instructions.
- Keep AppKit UI work on the main thread. Handle failures from Carbon, IOKit,
  and ServiceManagement without crashes or silently reporting success.
- Keep keyboard observation limited to the switching feature. Do not add typed
  text collection, clipboard access, telemetry, or background update polling.
- Add a focused regression check for nontrivial new logic when practical;
  hardware-dependent behavior also needs a documented manual check.
- If adding a Swift file, include it in the appropriate Xcode Sources phase.
  Avoid unrelated changes to signing teams, bundle IDs, entitlements, versions,
  or deployment targets.
- Do not include local `xcuserdata`, breakpoints, DerivedData, or build products
  in changes. Preserve pre-existing local changes.
