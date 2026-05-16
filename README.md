# LangSwitch
LangSwitch is a super-simple macOS app that switches your keyboard languages (input sources) one by one by pressing the Fn/Globe button. It aims to address the annoyance caused by the default macOS function, which includes a popup and a delay between source changes. The sole purpose of this app is to immediately change the language without any popups or delays.

# P.S.
MacOS Sonoma has improved language switching. They removed the popup, and switching is faster. But still it can be glitchy and works with bugs from time to time. So this app can still be relevant)

![langswitch-example](https://github.com/Nikeev/LangSwitch/assets/1555773/2850313a-f70d-4f76-b629-3d5798754f86)

**How to use:**
- Download and install the app from the releases page.
- Disable the default macOS Globe button click action in Keyboard settings.
- Run the LangSwitch app.

**Privacy and permissions:**
- LangSwitch does not read typed text.
- LangSwitch does not read the clipboard.
- LangSwitch does not include analytics, telemetry, or crash reporting.
- LangSwitch only monitors global `flagsChanged` modifier-key events to detect Fn/Globe presses.
- LangSwitch does not enable Launch at Login automatically. Use the menu bar icon to turn it on or off.
- LangSwitch only makes a network request when you manually click `Check for Updates` in the About window.
