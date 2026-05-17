import Foundation
internal import AppKit
import ApplicationServices

struct WindowEntry: Identifiable, Equatable {
    let id: UUID
    let cgWindowID: CGWindowID?
    let pid: pid_t
    let appName: String
    let title: String
    let icon: NSImage?
    let isMinimized: Bool
    /// Direct AX handle to the window. Required to raise minimized windows.
    let axWindow: AXUIElement?

    init(
        cgWindowID: CGWindowID?,
        pid: pid_t,
        appName: String,
        title: String,
        icon: NSImage?,
        isMinimized: Bool,
        axWindow: AXUIElement?
    ) {
        self.id = UUID()
        self.cgWindowID = cgWindowID
        self.pid = pid
        self.appName = appName
        self.title = title
        self.icon = icon
        self.isMinimized = isMinimized
        self.axWindow = axWindow
    }

    var displayTitle: String {
        title.isEmpty ? appName : title
    }

    static func == (lhs: WindowEntry, rhs: WindowEntry) -> Bool {
        lhs.id == rhs.id
    }
}
