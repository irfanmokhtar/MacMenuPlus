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
        } label: {
            Image(systemName: "doc.on.clipboard")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appDelegate.store)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ClipboardStore()
    let monitor = PasteboardMonitor()
    let switcherHUD = AppSwitcherHUD()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setvbuf(stdout, nil, _IONBF, 0)
        setvbuf(stderr, nil, _IONBF, 0)
        monitor.start(store: store)
        KeyboardShortcuts.onKeyUp(for: .togglePanel) { [weak self] in
            self?.togglePanel()
        }
        KeyboardShortcuts.onKeyDown(for: .switchApps) { [weak self] in
            _ = AccessibilityPermission.requestIfNeeded()
            self?.switcherHUD.show()
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
