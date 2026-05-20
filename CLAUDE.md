# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

MacMenu+ — macOS menu-bar utility (SwiftUI + AppKit). Two features share one menu-bar panel:
- Clipboard history (text + images, pin/unpin, configurable capacity).
- App/window switcher (lists every window across regular apps; HUD overlay activated by hotkey).

`LSUIElement = YES` → no Dock icon. Runs entirely from `MenuBarExtra`.

## Build / Run

Xcode project, no Package.swift, no fastlane, no tests target.

```sh
# Open in Xcode
open "MacMenu+.xcodeproj"

# CLI build (Debug)
xcodebuild -project "MacMenu+.xcodeproj" -scheme "MacMenu+" -configuration Debug build

# Build & run from CLI
xcodebuild -project "MacMenu+.xcodeproj" -scheme "MacMenu+" -configuration Debug build && \
  open "$(xcodebuild -project 'MacMenu+.xcodeproj' -scheme 'MacMenu+' -showBuildSettings | awk -F= '/ BUILT_PRODUCTS_DIR / {gsub(/ /,"",$2); print $2}')/MacMenu+.app"
```

Bundle id: `com.irfan.MacMenu-` (Xcode strips `+` from identifier).
Deployment target differs Debug vs Release in `project.pbxproj` (14.0 / 26.2) — fix if it matters before shipping.
Swift 5.0, single dependency: `KeyboardShortcuts` (SPM, sindresorhus/KeyboardShortcuts).

## Architecture

Entry: `MacMenu+/MacMenuPlusApp.swift`
- `@main MacMenuPlusApp` declares two `Scene`s: `MenuBarExtra` (panel) and `Settings`.
- `AppDelegate` owns three singletons injected via `.environment`: `ClipboardStore`, `PasteboardMonitor`, `AppSwitcherHUD`.
- Registers two global hotkeys via `KeyboardShortcuts.Name` (see `Hotkeys/HotkeyNames.swift`): `.togglePanel` (⌃⌥V), `.switchApps` (⌃⌥Tab).

Layered layout under `MacMenu+/`:
- `App/RootPanelView.swift` — composes feature sections vertically; fixed 360 width.
- `Models/` — value types (`ClipboardItem`, `WindowEntry`). `WindowEntry` carries an `AXUIElement` for direct raise.
- `Services/` — non-UI engines. Each owns one concern; UI consumes through `@Observable` or direct static calls.
- `Features/<Name>/` — SwiftUI views + per-feature controllers. Two features today: `Clipboard`, `AppSwitcher`.
- `Settings/SettingsView.swift` — Form-based settings (capacity stepper, hotkey recorders, AX permission state).
- `Hotkeys/HotkeyNames.swift` — single source for `KeyboardShortcuts.Name` definitions.

### Panel-toggle trick (`AppDelegate.togglePanel`)

`MenuBarExtra` auto-dismisses on focus loss only if open/close goes through the status item button. Code finds the hidden `NSStatusItem` via KVC (`window.value(forKey: "statusItem")`) and calls `button.performClick(nil)`. Do **not** replace with `makeKeyAndOrderFront` — auto-dismiss breaks.

### Clipboard pipeline

`PasteboardMonitor` polls `NSPasteboard.general.changeCount` every 0.5 s on the main run loop. On change it reads (image-first, then string) and pushes to `ClipboardStore.add`.

`ClipboardStore.ignoreNextChange` is a one-shot guard set before our own `copyToPasteboard` writes so the next monitor tick is skipped — without it every paste-back would re-add a duplicate entry. Always set this flag before mutating `NSPasteboard.general`.

`ClipboardStore.trim` enforces `capacity` but never evicts pinned items.

### Window switcher pipeline

`Services/WindowEnumerator.enumerate()` builds the window list in two passes:
1. **CG pass** — `CGWindowListCopyWindowInfo(.optionOnScreenOnly | .excludeDesktopElements)` filtered to layer 0 and regular-policy apps. Z-order preserved.
2. **AX pass** (only if `AXIsProcessTrusted()`) — iterates `runningApplications` and adds AX windows not consumed by the CG pass (minimized, hidden, fully-occluded). Provides titles CG often lacks.

CG↔AX correlation uses bounds: exact-rect match first, nearest-center fallback. The `consumedAX` set prevents one AX window matching twice.

Chromium/Electron quirk: lazy-AX apps return empty `kAXWindowsAttribute`. `fetchAXWindows` forces them on by setting `AXManualAccessibility` and `AXEnhancedUserInterface` on the application element. Keep these — removing them silently breaks Chrome/Slack/VS Code switching.

`Services/WindowActivator.activate(entry)` → `NSRunningApplication.activate()` for app focus, then if AX-trusted: unminimize (`kAXMinimizedAttribute = false`) and `kAXRaiseAction`. Fallback path matches by title when `entry.axWindow` is nil.

`Features/AppSwitcher/AppSwitcherHUD.swift` — floating `NSPanel` (subclass `KeyablePanel` overrides `canBecomeKey`). Local `NSEvent` monitor handles Tab/Shift-Tab/arrows/Return/Esc. `selectedIndex` defaults to `1` so a single Tab press jumps to the next window (classic ⌘-Tab behavior). Panel width 540pt; `hostedHeight()` computes from `rowHeight=64`, `chrome=110`, capped at 10 rows then scrolls.

`Features/AppSwitcher/WindowRowView.swift` is shared between the menu-bar panel section and the HUD via a `Style` enum (`.compact` / `.expanded`). All sizing metrics (icon, fonts, padding, corner radius, selection opacity) switch on `style`. Default is `.compact`; `AppSwitcherHUDView` passes `.expanded`. When tweaking row appearance, edit *both* branches or you'll break one surface.

`Features/AppSwitcher/AppSwitcherPanelSection.swift` has a user-resizable list height: `@AppStorage("appSwitcherListHeight")` (default 220). Drag handle below the `ScrollView` accumulates `dragDelta` during `DragGesture` and writes `listHeight` on `onEnded`. `NSCursor.resizeUpDown.push()/pop()` on hover.

Clamp is **dynamic**, not a static constant: `max(minHeight=120, min(absoluteMaxHeight=600, NSScreen.main.visibleFrame.height − reservedForClipboardAndChrome=520))`. The `reservedForClipboardAndChrome` budget exists because the switcher list uses a *fixed* `.frame(height:)` while clipboard's list uses `.frame(maxHeight:)` (flexible) — without the budget, SwiftUI compresses the clipboard list first when the panel exceeds available height, hiding clipboard rows. If you change clipboard chrome (header/search/footer/list cap) or switcher chrome (header/handle/dividers), recompute the 520 reservation.

Defense-in-depth: `Features/Clipboard/ClipboardPanelView.swift` sets `.frame(minHeight: 120, maxHeight: 320)` on its list so the clipboard list cannot collapse below 120pt under VStack pressure even if the budget math drifts.

### Permissions

App is non-sandboxed (`MacMenu+/MacMenuPlus.entitlements` is empty `<dict/>`); do not enable App Sandbox — it disables the AX API used by the switcher. `AccessibilityPermission.requestIfNeeded()` is called lazily on the first switcher hotkey press, not at launch.

### State / observation

`ClipboardStore` uses Swift `@Observable` (Observation framework, not `ObservableObject`). Inject via `.environment(store)` and read with `@Environment(ClipboardStore.self)`. Use `@Bindable var store = store` inside views to bind to its mutable properties.

## Conventions worth preserving

- `internal import AppKit` (Swift 5.9+ access-level imports) is used everywhere AppKit is referenced — keep the modifier; bare `import AppKit` will leak symbols out of the module for files compiled with stricter access checks.
- Print logging via `[Switcher] …` lines in `WindowEnumerator` is intentional diagnostic output for the AX correlation path. Leave or gate behind a flag; do not silently delete when debugging unrelated issues.
- No persistence layer for clipboard history — in-memory, cleared on quit (surfaced in Settings UI).
- UI-state persistence is limited to `@AppStorage` keys (UserDefaults-backed): `appSwitcherListHeight` (resizable open-windows section). Hotkey bindings persist via `KeyboardShortcuts` (also UserDefaults). No custom persistence service.
