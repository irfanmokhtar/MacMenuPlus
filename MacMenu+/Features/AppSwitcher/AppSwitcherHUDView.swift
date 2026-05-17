import SwiftUI

struct AppSwitcherHUDView: View {
    let entries: [WindowEntry]
    let selectedIndex: Int
    let onPick: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            if entries.isEmpty {
                Text("No other windows")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                                WindowRowView(
                                    entry: entry,
                                    isSelected: idx == selectedIndex,
                                    onActivate: { onPick(idx) }
                                )
                                .id(idx)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 420)
                    .onChange(of: selectedIndex) { _, new in
                        withAnimation(.easeOut(duration: 0.12)) {
                            proxy.scrollTo(new, anchor: .center)
                        }
                    }
                }
            }
            footer
        }
        .frame(width: 460)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThickMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "rectangle.stack")
            Text("Switch window").font(.headline)
            Spacer()
            Text("\(entries.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            label("⇥", "Next")
            label("⇧⇥", "Prev")
            label("↩", "Switch")
            label("⎋", "Cancel")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
        .padding(.top, 4)
    }

    private func label(_ key: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(.caption2, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.08)))
            Text(text)
        }
    }
}
