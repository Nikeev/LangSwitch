# LangSwitch hardening notes

Goal:
Make a safer fork of Nikeev/LangSwitch without changing the core idea:
instant macOS input source switching via Fn/Globe.

Main issues to fix:
1. Launch at Login must not be enabled automatically.
2. Hide Icon must not make the app invisible/uncontrollable.
3. Remove unsafe force casts / force unwraps where possible.
4. Replace string version comparison with numeric SemVer comparison.
5. Keep network request only for manual Check for Updates.
6. Clean up unnecessary entitlements.
7. Document privacy clearly:
   - no typed text reading;
   - no clipboard reading;
   - no analytics;
   - no telemetry;
   - only modifier key flagsChanged event is monitored.

Important files:
- LangSwitch/AppDelegate.swift
- LangSwitch/LangSwitchApp.swift
- LangSwitch/LangSwitch.entitlements
- README.md

Do not add:
- external dependencies;
- telemetry;
- analytics;
- auto-update frameworks;
- Accessibility permission unless strictly necessary;
- broad entitlements.

Preferred behavior:
- Launch at Login is off by default.
- User can toggle Launch at Login from menu.
- Menu shows the real SMAppService status.
- Hide Icon should preferably be removed unless a safe recovery path exists.
