import Foundation
internal import AppKit

/// A window-tiling target position. Frames are expressed in Cocoa screen coordinates
/// (bottom-left origin, y grows up). `WindowTiler` flips to AX coordinates when applying.
enum WindowTile: String, CaseIterable, Identifiable {
    case leftHalf, rightHalf, topHalf, bottomHalf
    case topLeft, topRight, bottomLeft, bottomRight
    case maximize, center

    var id: String { rawValue }

    /// Target rect within a screen's `visibleFrame` (Cocoa coords, bottom-left origin).
    func frame(in v: CGRect) -> CGRect {
        let w = v.width, h = v.height, x = v.minX, y = v.minY
        switch self {
        case .leftHalf:    return CGRect(x: x,       y: y,       width: w / 2, height: h)
        case .rightHalf:   return CGRect(x: x + w / 2, y: y,     width: w / 2, height: h)
        // Higher y == top, because Cocoa y grows upward.
        case .topHalf:     return CGRect(x: x,       y: y + h / 2, width: w,   height: h / 2)
        case .bottomHalf:  return CGRect(x: x,       y: y,       width: w,     height: h / 2)
        case .topLeft:     return CGRect(x: x,       y: y + h / 2, width: w / 2, height: h / 2)
        case .topRight:    return CGRect(x: x + w / 2, y: y + h / 2, width: w / 2, height: h / 2)
        case .bottomLeft:  return CGRect(x: x,       y: y,       width: w / 2, height: h / 2)
        case .bottomRight: return CGRect(x: x + w / 2, y: y,     width: w / 2, height: h / 2)
        case .maximize:    return v
        case .center:      return CGRect(x: x + w * 0.15, y: y + h * 0.15, width: w * 0.7, height: h * 0.7)
        }
    }

    /// SF Symbol shown in the panel grid.
    var symbol: String {
        switch self {
        case .leftHalf:    return "rectangle.lefthalf.filled"
        case .rightHalf:   return "rectangle.righthalf.filled"
        case .topHalf:     return "rectangle.tophalf.filled"
        case .bottomHalf:  return "rectangle.bottomhalf.filled"
        case .topLeft:     return "rectangle.inset.topleft.filled"
        case .topRight:    return "rectangle.inset.topright.filled"
        case .bottomLeft:  return "rectangle.inset.bottomleft.filled"
        case .bottomRight: return "rectangle.inset.bottomright.filled"
        case .maximize:    return "arrow.up.left.and.arrow.down.right"
        case .center:      return "rectangle.center.inset.filled"
        }
    }

    var label: String {
        switch self {
        case .leftHalf:    return "Left Half"
        case .rightHalf:   return "Right Half"
        case .topHalf:     return "Top Half"
        case .bottomHalf:  return "Bottom Half"
        case .topLeft:     return "Top Left"
        case .topRight:    return "Top Right"
        case .bottomLeft:  return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        case .maximize:    return "Maximize"
        case .center:      return "Center"
        }
    }
}
