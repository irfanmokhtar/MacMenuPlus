import Foundation
internal import AppKit
import ApplicationServices

/// Writes window position + size via the Accessibility API to snap a window into a `WindowTile`.
/// The codebase's other AX paths (`WindowActivator`, `WindowEnumerator`) only read frames and
/// raise/unminimize — this is the only place that *moves/resizes* a window.
enum WindowTiler {
    static func apply(_ tile: WindowTile, to window: AXUIElement) {
        guard AccessibilityPermission.isTrusted else { return }

        // A minimized window can't be repositioned meaningfully — restore it first.
        if copyBool(window, kAXMinimizedAttribute) == true {
            AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        }

        let screen = screenForWindow(window) ?? NSScreen.main
        guard let screen else { return }

        let cocoaRect = tile.frame(in: screen.visibleFrame)
        let axOrigin = cocoaToAX(origin: cocoaRect)

        // Set position → size → position again. The second position write defeats apps that
        // clamp to a minimum size on the first pass (same trick Rectangle uses).
        setPosition(window, axOrigin)
        setSize(window, cocoaRect.size)
        setPosition(window, axOrigin)
    }

    // MARK: - Coordinate conversion

    /// AX uses a top-left origin on the *primary* display (y grows down); Cocoa uses a
    /// bottom-left origin (y grows up). Flip the Cocoa rect's top-left corner into AX space.
    private static func cocoaToAX(origin rect: CGRect) -> CGPoint {
        let primaryHeight = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? NSScreen.main?.frame.height
            ?? rect.maxY
        return CGPoint(x: rect.minX, y: primaryHeight - rect.maxY)
    }

    /// Pick the screen containing the window's current center; fall back to main.
    private static func screenForWindow(_ window: AXUIElement) -> NSScreen? {
        guard let frame = copyFrame(window) else { return nil }
        // `frame` is in AX (top-left) coords; convert its center back to Cocoa to test containment.
        let primaryHeight = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? NSScreen.main?.frame.height
            ?? frame.maxY
        let cocoaCenter = CGPoint(x: frame.midX, y: primaryHeight - frame.midY)
        return NSScreen.screens.first(where: { $0.frame.contains(cocoaCenter) })
    }

    // MARK: - AX setters / getters

    private static func setPosition(_ window: AXUIElement, _ point: CGPoint) {
        var p = point
        guard let value = AXValueCreate(.cgPoint, &p) else { return }
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
    }

    private static func setSize(_ window: AXUIElement, _ size: CGSize) {
        var s = size
        guard let value = AXValueCreate(.cgSize, &s) else { return }
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
    }

    private static func copyFrame(_ element: AXUIElement) -> CGRect? {
        var posRaw: CFTypeRef?
        var sizeRaw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRaw) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRaw) == .success
        else { return nil }

        var position = CGPoint.zero
        var size = CGSize.zero
        if let posVal = posRaw, CFGetTypeID(posVal) == AXValueGetTypeID() {
            AXValueGetValue(posVal as! AXValue, .cgPoint, &position)
        }
        if let sizeVal = sizeRaw, CFGetTypeID(sizeVal) == AXValueGetTypeID() {
            AXValueGetValue(sizeVal as! AXValue, .cgSize, &size)
        }
        return CGRect(origin: position, size: size)
    }

    private static func copyBool(_ element: AXUIElement, _ attr: String) -> Bool? {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attr as CFString, &raw) == .success,
              let value = raw
        else { return nil }
        if CFGetTypeID(value) == CFBooleanGetTypeID() {
            return CFBooleanGetValue((value as! CFBoolean))
        }
        return (value as? NSNumber)?.boolValue
    }
}
