import SwiftUI
internal import AppKit

final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class AppSwitcherHUD {
    private var panel: NSPanel?
    private var eventMonitor: Any?
    private var entries: [WindowEntry] = []
    private var selectedIndex: Int = 0

    func show() {
        let snapshot = WindowEnumerator.enumerateForHUD()
        guard !snapshot.isEmpty else {
            NSSound.beep()
            return
        }
        entries = snapshot
        selectedIndex = min(1, snapshot.count - 1)

        let panel = panel ?? makePanel()
        self.panel = panel

        renderHostedView()
        positionPanelCentered(panel)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        installEventMonitor()
    }

    func hide() {
        removeEventMonitor()
        panel?.orderOut(nil)
    }

    private func commit() {
        let pick = selectedIndex
        let list = entries
        hide()
        guard list.indices.contains(pick) else { return }
        WindowActivator.activate(list[pick])
    }

    private func makePanel() -> NSPanel {
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isOpaque = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.becomesKeyOnlyIfNeeded = false
        return panel
    }

    private func renderHostedView() {
        guard let panel else { return }
        let view = AppSwitcherHUDView(
            entries: entries,
            selectedIndex: selectedIndex,
            onPick: { [weak self] idx in
                self?.selectedIndex = idx
                self?.commit()
            }
        )
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 540, height: hostedHeight())
        panel.setContentSize(hosting.frame.size)
        panel.contentView = hosting
    }

    private func refreshHostedView() {
        guard let hosting = panel?.contentView as? NSHostingView<AppSwitcherHUDView> else {
            renderHostedView()
            return
        }
        hosting.rootView = AppSwitcherHUDView(
            entries: entries,
            selectedIndex: selectedIndex,
            onPick: { [weak self] idx in
                self?.selectedIndex = idx
                self?.commit()
            }
        )
    }

    private func hostedHeight() -> CGFloat {
        let rowHeight: CGFloat = 64
        let chrome: CGFloat = 110
        let rows = min(CGFloat(max(entries.count, 1)), 10)
        return chrome + rows * rowHeight
    }

    private func positionPanelCentered(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.midY - size.height / 2
        )
        panel.setFrameOrigin(origin)
    }

    private func installEventMonitor() {
        removeEventMonitor()
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handle(event)
        }
    }

    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        guard panel?.isVisible == true else { return event }

        let shift = event.modifierFlags.contains(.shift)
        switch event.keyCode {
        case 48: // Tab
            advance(shift ? -1 : +1)
            return nil
        case 36, 76: // Return / numpad Enter
            commit()
            return nil
        case 53: // Esc
            hide()
            return nil
        case 125: // Down
            advance(+1)
            return nil
        case 126: // Up
            advance(-1)
            return nil
        default:
            return event
        }
    }

    private func advance(_ step: Int) {
        guard !entries.isEmpty else { return }
        let count = entries.count
        selectedIndex = (selectedIndex + step + count) % count
        refreshHostedView()
    }
}
