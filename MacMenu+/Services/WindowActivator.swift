import Foundation
internal import AppKit
import ApplicationServices

enum WindowActivator {
    static func activate(_ entry: WindowEntry) {
        if let app = NSRunningApplication(processIdentifier: entry.pid) {
            app.activate(options: [])
        }

        guard AccessibilityPermission.isTrusted else { return }

        if let direct = entry.axWindow {
            if entry.isMinimized {
                AXUIElementSetAttributeValue(direct, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            }
            AXUIElementPerformAction(direct, kAXRaiseAction as CFString)
            return
        }
        fallbackRaiseByTitle(entry)
    }

    private static func fallbackRaiseByTitle(_ entry: WindowEntry) {
        let appElement = AXUIElementCreateApplication(entry.pid)
        var rawWindows: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &rawWindows) == .success,
              let windows = rawWindows as? [AXUIElement]
        else { return }

        let target = windows.first(where: { matchesTitle($0, entry.title) }) ?? windows.first
        guard let window = target else { return }
        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
    }

    private static func matchesTitle(_ window: AXUIElement, _ expected: String) -> Bool {
        guard !expected.isEmpty else { return false }
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &raw) == .success,
              let title = raw as? String
        else { return false }
        return title == expected
    }
}
