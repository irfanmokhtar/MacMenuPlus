# MacMenu+

macOS menu-bar utility combining clipboard history and a window switcher into a single status-bar panel. No Dock icon. Lives entirely in the menu bar.

## Features

### Clipboard History
- Captures text and images automatically
- Search across history
- Pin items to keep them across clears
- Configurable capacity (10–200 items, default 50)
- Clear all unpinned items in one click
- History is in-memory — cleared on quit

### Window Switcher HUD
- Floating overlay lists every open window across all apps
- Keyboard-driven: Tab / Shift-Tab to move, Return to switch, Esc to cancel
- Enumerates minimized and hidden windows (requires Accessibility permission)
- Handles Chromium/Electron apps (Chrome, Slack, VS Code)

## Hotkeys

| Action | Default |
|---|---|
| Toggle menu-bar panel | `⌃⌥V` |
| Open window switcher | `⌃⌥Tab` |

Both are rebindable in **Settings → Shortcuts**.

## Requirements

- macOS 14+
- Xcode 15+ (to build from source)
- Accessibility permission for window-raise (switcher works without it, but can only focus the app — not a specific window)

## Build

```sh
git clone https://github.com/your-username/MacMenu-.git
cd MacMenu-

# Open in Xcode
open "MacMenu+.xcodeproj"
```

Or build from the command line:

```sh
xcodebuild -project "MacMenu+.xcodeproj" -scheme "MacMenu+" -configuration Debug build
```

> **Note:** The bundle identifier is `com.irfan.MacMenu-` — Xcode strips `+` from bundle IDs automatically.

## Permissions

MacMenu+ is **not sandboxed**. The Accessibility API used by the window switcher is incompatible with App Sandbox.

On first switcher activation, the app prompts for Accessibility permission. You can also grant it manually:

**System Settings → Privacy & Security → Accessibility → MacMenu+**

## Architecture

```
MacMenu+/
├── App/              # RootPanelView — composes both feature sections
├── Features/
│   ├── Clipboard/    # ClipboardPanelView, ClipboardRowView
│   └── AppSwitcher/  # AppSwitcherHUD (NSPanel), HUDView, WindowRowView
├── Models/           # ClipboardItem, WindowEntry
├── Services/         # ClipboardStore, PasteboardMonitor, WindowEnumerator, WindowActivator
├── Settings/         # SettingsView
└── Hotkeys/          # KeyboardShortcuts.Name definitions
```

Single dependency: [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) (SPM).

## License

MIT
