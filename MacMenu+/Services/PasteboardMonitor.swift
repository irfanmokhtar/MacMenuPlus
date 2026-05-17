import Foundation
internal import AppKit

final class PasteboardMonitor {
    private weak var store: ClipboardStore?
    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private let interval: TimeInterval

    init(interval: TimeInterval = 0.5) {
        self.interval = interval
    }

    func start(store: ClipboardStore) {
        self.store = store
        stop()
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        guard let store = store else { return }
        if store.ignoreNextChange {
            store.ignoreNextChange = false
            return
        }

        if let item = readItem(from: pb) {
            store.add(item)
        }
    }

    private func readItem(from pb: NSPasteboard) -> ClipboardItem? {
        // Prefer image when present (screenshots etc.)
        if let data = pb.data(forType: .tiff), let img = NSImage(data: data) {
            return ClipboardItem(payload: .image(img))
        }
        if let data = pb.data(forType: .png), let img = NSImage(data: data) {
            return ClipboardItem(payload: .image(img))
        }
        if let s = pb.string(forType: .string), !s.isEmpty {
            return ClipboardItem(payload: .text(s))
        }
        return nil
    }
}
