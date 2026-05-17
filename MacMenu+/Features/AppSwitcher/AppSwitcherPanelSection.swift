import SwiftUI

struct AppSwitcherPanelSection: View {
    @State private var entries: [WindowEntry] = []

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
        .frame(maxHeight: 220)
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
