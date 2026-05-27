import Foundation
internal import AppKit
import ApplicationServices
import Observation

/// Tracks the most recently active *other* app so tiling can target it even after our
/// menu-bar panel steals focus. Hotkeys hit the live frontmost app; panel buttons fall back
/// to this remembered app (since when the panel is open, *we* are frontmost).
@Observable
final class FrontmostAppTracker {
    private(set) var lastActivePID: pid_t?
    private(set) var lastActiveAppName: String?

    private let ownPID = ProcessInfo.processInfo.processIdentifier

    func start() {
        // Seed with whatever is frontmost right now.
        if let app = NSWorkspace.shared.frontmostApplication, app.processIdentifier != ownPID {
            record(app)
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            else { return }
            self.record(app)
        }
    }

    private func record(_ app: NSRunningApplication) {
        guard app.processIdentifier != ownPID, app.activationPolicy == .regular else { return }
        lastActivePID = app.processIdentifier
        lastActiveAppName = app.localizedName
    }

    // MARK: - Targeting

    /// The window to tile: the live frontmost app if it isn't us (hotkey path), else the last
    /// remembered app (panel path, where the panel itself holds focus).
    func targetPID() -> pid_t? {
        if let front = NSWorkspace.shared.frontmostApplication, front.processIdentifier != ownPID {
            return front.processIdentifier
        }
        return lastActivePID
    }

    private func focusedWindow(pid: pid_t) -> AXUIElement? {
        let app = AXUIElementCreateApplication(pid)
        // Mirror WindowEnumerator: force Chromium/Electron apps to expose their AX tree.
        AXUIElementSetAttributeValue(app, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)

        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &raw) == .success,
              let value = raw, CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return (value as! AXUIElement)
    }

    /// Resolve the target window and apply the tile. No-op if nothing resolves.
    func tile(_ tile: WindowTile) {
        guard let pid = targetPID(), let window = focusedWindow(pid: pid) else { return }
        WindowTiler.apply(tile, to: window)
    }
}
