internal import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel", default: .init(.v, modifiers: [.control, .option]))
    static let switchApps = Self("switchApps", default: .init(.tab, modifiers: [.control, .option]))
}
