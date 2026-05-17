import Foundation
internal import AppKit
import ApplicationServices

enum WindowEnumerator {
    /// Snapshot of windows across all regular apps. Visible windows come first in
    /// CGWindowList z-order; minimized / off-screen windows are appended after.
    /// Titles + AX handles are sourced from the Accessibility API when granted —
    /// without it, only visible windows are listed and titles may be empty.
    static func enumerate() -> [WindowEntry] {
        let myPid = ProcessInfo.processInfo.processIdentifier
        let axTrusted = AccessibilityPermission.isTrusted
        print("[Switcher] enumerate axTrusted=\(axTrusted)")

        var visible: [WindowEntry] = []
        var iconCache: [pid_t: NSImage?] = [:]
        var policyCache: [pid_t: NSApplication.ActivationPolicy] = [:]
        var axWindowsByPid: [pid_t: [AXWindowInfo]] = [:]
        var consumedAX: [pid_t: Set<Int>] = [:]
        var pidsSeen: Set<pid_t> = []

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        let cgList = (CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]) ?? []

        for dict in cgList {
            guard let layer = dict[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let pidNum = dict[kCGWindowOwnerPID as String] as? Int32 else { continue }
            let pid = pid_t(pidNum)
            if pid == myPid { continue }
            guard isRegular(pid, cache: &policyCache) else { continue }

            pidsSeen.insert(pid)
            guard let windowNum = dict[kCGWindowNumber as String] as? CGWindowID else { continue }
            let appName = (dict[kCGWindowOwnerName as String] as? String) ?? "Unknown"
            let cgTitle = (dict[kCGWindowName as String] as? String) ?? ""
            let bounds = cgBounds(dict[kCGWindowBounds as String])

            var title = cgTitle
            var axWindow: AXUIElement?

            if axTrusted {
                let axList = axWindowsByPid[pid] ?? fetchAXWindows(pid: pid)
                axWindowsByPid[pid] = axList
                if let matchIdx = bestAXMatchIndex(axList, bounds: bounds, exclude: consumedAX[pid] ?? []) {
                    let match = axList[matchIdx]
                    axWindow = match.element
                    if !match.title.isEmpty { title = match.title }
                    var consumed = consumedAX[pid] ?? []
                    consumed.insert(matchIdx)
                    consumedAX[pid] = consumed
                }
            }

            print("[Switcher]  cg pid=\(pid) app=\(appName) cgTitle='\(cgTitle)' axTitle='\(axWindow != nil ? title : "<none>")' axCount=\(axWindowsByPid[pid]?.count ?? 0)")

            visible.append(WindowEntry(
                cgWindowID: windowNum,
                pid: pid,
                appName: appName,
                title: title,
                icon: iconFor(pid, cache: &iconCache),
                isMinimized: false,
                axWindow: axWindow
            ))
        }

        guard axTrusted else { return visible }

        // Second pass: pick up windows that CG didn't list (minimized, hidden, or apps
        // with all windows minimized so they never appeared in cgList).
        var minimized: [WindowEntry] = []
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            let pid = app.processIdentifier
            if pid == myPid { continue }

            let axList = axWindowsByPid[pid] ?? fetchAXWindows(pid: pid)
            axWindowsByPid[pid] = axList
            let consumed = consumedAX[pid] ?? []

            for (idx, info) in axList.enumerated() where !consumed.contains(idx) {
                guard info.title.isEmpty == false || info.isMinimized else { continue }
                print("[Switcher]  ax-only pid=\(pid) app=\(app.localizedName ?? "?") title='\(info.title)' minimized=\(info.isMinimized)")
                minimized.append(WindowEntry(
                    cgWindowID: nil,
                    pid: pid,
                    appName: app.localizedName ?? "Unknown",
                    title: info.title,
                    icon: iconFor(pid, cache: &iconCache),
                    isMinimized: info.isMinimized,
                    axWindow: info.element
                ))
            }
        }

        return visible + minimized
    }

    static func enumerateForHUD() -> [WindowEntry] {
        enumerate()
    }

    // MARK: - Caches

    private static func isRegular(_ pid: pid_t, cache: inout [pid_t: NSApplication.ActivationPolicy]) -> Bool {
        if let cached = cache[pid] { return cached == .regular }
        let policy = NSRunningApplication(processIdentifier: pid)?.activationPolicy ?? .prohibited
        cache[pid] = policy
        return policy == .regular
    }

    private static func iconFor(_ pid: pid_t, cache: inout [pid_t: NSImage?]) -> NSImage? {
        if let cached = cache[pid] { return cached }
        let icon = NSRunningApplication(processIdentifier: pid)?.icon
        cache[pid] = icon
        return icon
    }

    // MARK: - AX

    private struct AXWindowInfo {
        let element: AXUIElement
        let title: String
        let frame: CGRect
        let isMinimized: Bool
    }

    private static func fetchAXWindows(pid: pid_t) -> [AXWindowInfo] {
        let app = AXUIElementCreateApplication(pid)

        // Force Chromium / Electron apps to expose their AX tree. They enable
        // accessibility lazily and otherwise return an empty windows array or
        // empty titles. Calls are no-ops on apps that don't honor them.
        AXUIElementSetAttributeValue(app, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)

        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &raw) == .success,
              let windows = raw as? [AXUIElement]
        else { return [] }

        return windows.map { window in
            AXWindowInfo(
                element: window,
                title: copyStringAttr(window, kAXTitleAttribute) ?? "",
                frame: copyFrameAttr(window) ?? .zero,
                isMinimized: copyBoolAttr(window, kAXMinimizedAttribute) ?? false
            )
        }
    }

    private static func bestAXMatchIndex(_ list: [AXWindowInfo], bounds: CGRect?, exclude: Set<Int>) -> Int? {
        let candidates = list.indices.filter { !exclude.contains($0) && !list[$0].isMinimized }
        guard !candidates.isEmpty else { return nil }
        guard let bounds else { return candidates.first }
        if let exact = candidates.first(where: { rectsEqual(list[$0].frame, bounds) }) {
            return exact
        }
        let target = CGPoint(x: bounds.midX, y: bounds.midY)
        return candidates.min(by: { distance(list[$0].frame, to: target) < distance(list[$1].frame, to: target) })
    }

    private static func copyStringAttr(_ element: AXUIElement, _ attr: String) -> String? {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attr as CFString, &raw) == .success else { return nil }
        return raw as? String
    }

    private static func copyBoolAttr(_ element: AXUIElement, _ attr: String) -> Bool? {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attr as CFString, &raw) == .success,
              let value = raw
        else { return nil }
        if CFGetTypeID(value) == CFBooleanGetTypeID() {
            return CFBooleanGetValue((value as! CFBoolean))
        }
        return (value as? NSNumber)?.boolValue
    }

    private static func copyFrameAttr(_ element: AXUIElement) -> CGRect? {
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

    // MARK: - Geometry

    private static func cgBounds(_ raw: Any?) -> CGRect? {
        guard let dict = raw as? [String: Any],
              let rect = CGRect(dictionaryRepresentation: dict as CFDictionary)
        else { return nil }
        return rect
    }

    private static func rectsEqual(_ a: CGRect, _ b: CGRect, tolerance: CGFloat = 2.0) -> Bool {
        abs(a.origin.x - b.origin.x) <= tolerance &&
        abs(a.origin.y - b.origin.y) <= tolerance &&
        abs(a.size.width - b.size.width) <= tolerance &&
        abs(a.size.height - b.size.height) <= tolerance
    }

    private static func distance(_ rect: CGRect, to point: CGPoint) -> CGFloat {
        let dx = rect.midX - point.x
        let dy = rect.midY - point.y
        return dx * dx + dy * dy
    }
}
