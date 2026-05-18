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
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                                WindowRowView(
                                    entry: entry,
                                    isSelected: idx == selectedIndex,
                                    style: .expanded,
                                    onActivate: { onPick(idx) }
                                )
                                .id(idx)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 520)
                    .onChange(of: selectedIndex) { _, new in
                        withAnimation(.easeOut(duration: 0.12)) {
                            proxy.scrollTo(new, anchor: .center)
                        }
                    }
                }
            }
            footer
        }
        .frame(width: 540)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThickMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.stack")
                .font(.title3)
            Text("Switch window").font(.title3.weight(.semibold))
            Spacer()
            Text("\(entries.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
    }

    private var footer: some View {
        HStack(spacing: 14) {
            label("⇥", "Next")
            label("⇧⇥", "Prev")
            label("↩", "Switch")
            label("⎋", "Cancel")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
        .padding(.top, 6)
    }

    private func label(_ key: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Text(key)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 5).fill(.white.opacity(0.08)))
            Text(text)
        }
    }
}
