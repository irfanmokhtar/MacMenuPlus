# MacMenu+

macOS menu-bar utility combining clipboard history, a window switcher, and window tiling into a single status-bar panel. No Dock icon. Lives entirely in the menu bar.

📄 Full feature docs: [`docs/index.html`](docs/index.html)

## Features

### Clipboard History
- Captures text and images automatically
- Search across history
- Pin items to keep them across clears
- Configurable capacity (10–200 items, default 50)
- Clear all unpinned items in one click
- History is in-memory — cleared on quit

### Window Switcher
- **Panel section** — scrollable, resizable list of every open window; click to raise
- **HUD overlay** (`⌃⌥Tab`) — floating, keyboard-driven switcher: Tab / Shift-Tab to move, Return to switch, Esc to cancel
- Enumerates minimized and hidden windows (requires Accessibility permission)
- Handles Chromium/Electron apps (Chrome, Slack, VS Code)

### Window Tiling
- Snap windows to **halves, quarters, maximize, or center** — including the quarter positions macOS has no built-in shortcut for
- **Panel grid** tiles the last-active app; **hotkeys** tile the current frontmost window
- Multi-monitor aware; respects the menu bar / Dock
- Rectangle-style default shortcuts, all rebindable
- Moves/resizes via the Accessibility API (requires Accessibility permission)

## Hotkeys

| Action | Default |
|---|---|
| Toggle menu-bar panel | `⌃⌥V` |
| Open window switcher | `⌃⌥Tab` |
| Tile — left / right / top / bottom half | `⌃⌥←` / `⌃⌥→` / `⌃⌥↑` / `⌃⌥↓` |
| Tile — top-left / top-right quarter | `⌃⌥U` / `⌃⌥I` |
| Tile — bottom-left / bottom-right quarter | `⌃⌥J` / `⌃⌥K` |
| Tile — maximize / center | `⌃⌥↩` / `⌃⌥C` |

All are rebindable in **Settings → Shortcuts** and **Settings → Tiling**.

## Requirements

- macOS 14+
- Xcode 15+ (to build from source)
- Accessibility permission for window-raise and tiling (switcher works without it, but can only focus the app — not a specific window; tiling needs it to move/resize windows)

## Build

```sh
git clone https://github.com/irfanmokhtar/MacMenuPlus.git
cd MacMenuPlus

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
├── App/              # RootPanelView — composes the three feature sections
├── Features/
│   ├── Clipboard/    # ClipboardPanelView, ClipboardRowView
│   ├── AppSwitcher/  # AppSwitcherHUD (NSPanel), HUDView, PanelSection, WindowRowView
│   └── Tiling/       # TilingPanelSection
├── Models/           # ClipboardItem, WindowEntry, WindowTile
├── Services/         # ClipboardStore, PasteboardMonitor, WindowEnumerator,
│                     #   WindowActivator, WindowTiler, FrontmostAppTracker
├── Settings/         # SettingsView
└── Hotkeys/          # KeyboardShortcuts.Name definitions
```

Single dependency: [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) (SPM).

## License

MIT
