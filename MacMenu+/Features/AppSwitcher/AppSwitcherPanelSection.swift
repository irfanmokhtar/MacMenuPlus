import SwiftUI

struct AppSwitcherPanelSection: View {
    @State private var entries: [WindowEntry] = []
    @AppStorage("appSwitcherListHeight") private var listHeight: Double = 220
    @State private var dragDelta: CGFloat = 0

    private static let minHeight: CGFloat = 120
    private static let maxHeight: CGFloat = 600

    private var clampedHeight: CGFloat {
        max(Self.minHeight, min(Self.maxHeight, CGFloat(listHeight) + dragDelta))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if entries.isEmpty {
                empty
            } else {
                list
            }
        }
        .task {
            refresh()
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "rectangle.stack")
            Text("Open windows").font(.headline)
            Spacer()
            Button {
                refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh window list")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var list: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(entries) { entry in
                        WindowRowView(entry: entry) {
                            WindowActivator.activate(entry)
                            NSApp.keyWindow?.close()
                        }
                        Divider()
                    }
                }
            }
            .frame(height: clampedHeight)
            resizeHandle
        }
    }

    private var resizeHandle: some View {
        ZStack {
            Rectangle()
                .fill(Color.clear)
                .frame(height: 8)
            Capsule()
                .fill(.tertiary)
                .frame(width: 28, height: 3)
        }
        .contentShape(Rectangle())
        .onHover { inside in
            if inside {
                NSCursor.resizeUpDown.push()
            } else {
                NSCursor.pop()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    dragDelta = value.translation.height
                }
                .onEnded { _ in
                    listHeight = Double(clampedHeight)
                    dragDelta = 0
                }
        )
    }

    private var empty: some View {
        VStack(spacing: 6) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
            Text("No other windows")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func refresh() {
        entries = WindowEnumerator.enumerate()
    }
}
