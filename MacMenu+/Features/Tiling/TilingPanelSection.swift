import SwiftUI

/// Menu-bar panel section: click a tile to snap the last-active window into that position.
struct TilingPanelSection: View {
    @Environment(FrontmostAppTracker.self) private var tracker

    private let halves: [WindowTile] = [.leftHalf, .rightHalf, .topHalf, .bottomHalf]
    private let quarters: [WindowTile] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
    private let extras: [WindowTile] = [.maximize, .center]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            grid
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.2x2")
            Text("Tile window").font(.headline)
            Spacer()
            if let name = tracker.lastActiveAppName {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .help("Tiling acts on \(name)")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var grid: some View {
        VStack(spacing: 6) {
            row(halves)
            row(quarters)
            row(extras)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func row(_ tiles: [WindowTile]) -> some View {
        HStack(spacing: 6) {
            ForEach(tiles) { tile in
                Button {
                    tracker.tile(tile)
                } label: {
                    Image(systemName: tile.symbol)
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity, minHeight: 30)
                }
                .buttonStyle(.bordered)
                .help(tile.label)
            }
        }
    }
}
