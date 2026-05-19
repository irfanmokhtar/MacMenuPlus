import SwiftUI

struct ClipboardPanelView: View {
    @Environment(ClipboardStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @State private var query: String = ""

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
            Text("Clipboard").font(.headline)
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
            .frame(minHeight: 120, maxHeight: 320)
        }
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
