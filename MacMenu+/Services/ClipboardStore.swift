import Foundation
internal import AppKit
import Observation

@Observable
final class ClipboardStore {
    private(set) var items: [ClipboardItem] = []
    var capacity: Int = 50 {
        didSet { trim() }
    }

    /// Bumped when we write to the pasteboard ourselves so the monitor can skip the resulting changeCount tick.
    var ignoreNextChange: Bool = false

    func add(_ item: ClipboardItem) {
        if let first = items.first, first == item { return }
        items.insert(item, at: 0)
        trim()
    }

    func remove(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
    }

    func togglePin(_ item: ClipboardItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isPinned.toggle()
    }

    func clear() {
        items.removeAll { !$0.isPinned }
    }

    func copyToPasteboard(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        ignoreNextChange = true
        pb.clearContents()
        switch item.payload {
        case .text(let s):
            pb.setString(s, forType: .string)
        case .image(let img):
            if let tiff = img.tiffRepresentation {
                pb.setData(tiff, forType: .tiff)
            }
        }
    }

    private func trim() {
        var unpinned = items.indices.filter { !items[$0].isPinned }
        while unpinned.count > capacity {
            items.remove(at: unpinned.removeLast())
        }
    }
}
