import SwiftUI

struct ClipboardPanelView: View {
    @Environment(ClipboardStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @State private var query: String = ""
    @AppStorage("clipboardListHeight") private var listHeight: Double = 220
    @State private var dragDelta: CGFloat = 0

    private static let minHeight: CGFloat = 120
    private static let absoluteMaxHeight: CGFloat = 600

    private var dynamicMaxHeight: CGFloat {
        let screenH = NSScreen.main?.visibleFrame.height ?? 900
        // Leave room for the switcher section + chrome (mirrors the switcher's reservation).
        let available = screenH - 520
        return max(Self.minHeight, min(Self.absoluteMaxHeight, available))
    }

    private var clampedHeight: CGFloat {
        max(Self.minHeight, min(dynamicMaxHeight, CGFloat(listHeight) + dragDelta))
    }

    private var filtered: [ClipboardItem] {
        let src = query.isEmpty ? store.items : store.items.filter {
            $0.searchableText.localizedCaseInsensitiveContains(query)
        }
        return src.filter(\.isPinned) + src.filter { !$0.isPinned }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if store.items.isEmpty {
                empty
            } else {
                list
            }
            Divider()
            footer
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
            Text("MacMenu+").font(.headline)
            Spacer()
            Button {
                store.clear()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Clear unpinned")
            .disabled(store.items.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var list: some View {
        VStack(spacing: 0) {
            TextField("Search", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { item in
                        ClipboardRowView(
                            item: item,
                            onCopy: {
                                store.copyToPasteboard(item)
                                NSApp.keyWindow?.close()
                            },
                            onDelete: { store.remove(item) },
                            onPin: { store.togglePin(item) }
                        )
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
        VStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("No clipboard history yet")
                .foregroundStyle(.secondary)
            Text("Copy something to get started")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private var footer: some View {
        HStack {
            Text("\(store.items.count) item\(store.items.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("Settings")
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
