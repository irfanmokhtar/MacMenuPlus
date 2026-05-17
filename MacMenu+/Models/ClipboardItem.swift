import Foundation
internal import AppKit

struct ClipboardItem: Identifiable, Equatable {
    enum Payload: Equatable {
        case text(String)
        case image(NSImage)

        static func == (lhs: Payload, rhs: Payload) -> Bool {
            switch (lhs, rhs) {
            case let (.text(a), .text(b)): return a == b
            case let (.image(a), .image(b)): return a.tiffRepresentation == b.tiffRepresentation
            default: return false
            }
        }
    }

    let id = UUID()
    let payload: Payload
    let createdAt = Date()
    var isPinned: Bool = false

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.payload == rhs.payload
    }

    var isText: Bool { if case .text = payload { return true }; return false }
    var isImage: Bool { if case .image = payload { return true }; return false }

    var textValue: String? { if case let .text(s) = payload { return s }; return nil }
    var imageValue: NSImage? { if case let .image(i) = payload { return i }; return nil }

    var searchableText: String {
        switch payload {
        case .text(let s): return s
        case .image: return "image"
        }
    }
}
