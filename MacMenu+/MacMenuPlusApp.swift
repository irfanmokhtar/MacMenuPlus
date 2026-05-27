import SwiftUI
internal import AppKit
import KeyboardShortcuts

@main
struct MacMenuPlusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            RootPanelView()
                .environment(appDelegate.store)
                .environment(appDelegate.frontmostTracker)
        } label: {
            Image(systemName: "doc.on.clipboard")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appDelegate.store)
                .environment(appDelegate.frontmostTracker)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ClipboardStore()
    let monitor = PasteboardMonitor()
    let switcherHUD = AppSwitcherHUD()
    let frontmostTracker = FrontmostAppTracker()

    /// Maps each tiling hotkey to the tile it applies.
    private let tileHotkeys: [(KeyboardShortcuts.Name, WindowTile)] = [
        (.tileLeftHalf, .leftHalf), (.tileRightHalf, .rightHalf),
        (.tileTopHalf, .topHalf), (.tileBottomHalf, .bottomHalf),
        (.tileTopLeft, .topLeft), (.tileTopRight, .topRight),
        (.tileBottomLeft, .bottomLeft), (.tileBottomRight, .bottomRight),
        (.tileMaximize, .maximize), (.tileCenter, .center),
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        setvbuf(stdout, nil, _IONBF, 0)
        setvbuf(stderr, nil, _IONBF, 0)
        monitor.start(store: store)
        frontmostTracker.start()
        KeyboardShortcuts.onKeyUp(for: .togglePanel) { [weak self] in
            self?.togglePanel()
        }
        KeyboardShortcuts.onKeyDown(for: .switchApps) { [weak self] in
            _ = AccessibilityPermission.requestIfNeeded()
            self?.switcherHUD.show()
        }
        for (name, tile) in tileHotkeys {
            KeyboardShortcuts.onKeyDown(for: name) { [weak self] in
                _ = AccessibilityPermission.requestIfNeeded()
                self?.frontmostTracker.tile(tile)
            }
        }
    }

    /// Simulate a click on the menu-bar status item to open/close the panel.
    /// Routing through the status item button (not `makeKeyAndOrderFront` on the panel window)
    /// preserves MenuBarExtra's auto-dismiss on focus loss.
    func togglePanel() {
        for window in NSApp.windows {
            if let statusItem = window.value(forKey: "statusItem") as? NSStatusItem,
               let button = statusItem.button {
                button.performClick(nil)
                return
            }
        }
    }
}
