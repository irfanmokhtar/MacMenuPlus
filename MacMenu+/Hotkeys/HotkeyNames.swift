internal import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel", default: .init(.v, modifiers: [.control, .option]))
    static let switchApps = Self("switchApps", default: .init(.tab, modifiers: [.control, .option]))

    // Window tiling — Rectangle-style defaults. All editable in Settings.
    static let tileLeftHalf    = Self("tileLeftHalf",    default: .init(.leftArrow,  modifiers: [.control, .option]))
    static let tileRightHalf   = Self("tileRightHalf",   default: .init(.rightArrow, modifiers: [.control, .option]))
    static let tileTopHalf     = Self("tileTopHalf",     default: .init(.upArrow,    modifiers: [.control, .option]))
    static let tileBottomHalf  = Self("tileBottomHalf",  default: .init(.downArrow,  modifiers: [.control, .option]))
    static let tileTopLeft     = Self("tileTopLeft",     default: .init(.u, modifiers: [.control, .option]))
    static let tileTopRight    = Self("tileTopRight",    default: .init(.i, modifiers: [.control, .option]))
    static let tileBottomLeft  = Self("tileBottomLeft",  default: .init(.j, modifiers: [.control, .option]))
    static let tileBottomRight = Self("tileBottomRight", default: .init(.k, modifiers: [.control, .option]))
    static let tileMaximize    = Self("tileMaximize",    default: .init(.return, modifiers: [.control, .option]))
    static let tileCenter      = Self("tileCenter",      default: .init(.c, modifiers: [.control, .option]))
}
