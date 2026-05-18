import SwiftUI

struct WindowRowView: View {
    enum Style {
        case compact, expanded
    }

    let entry: WindowEntry
    let isSelected: Bool
    let style: Style
    let onActivate: () -> Void

    init(
        entry: WindowEntry,
        isSelected: Bool = false,
        style: Style = .compact,
        onActivate: @escaping () -> Void
    ) {
        self.entry = entry
        self.isSelected = isSelected
        self.style = style
        self.onActivate = onActivate
    }

    var body: some View {
        Button(action: onActivate) {
            HStack(spacing: innerSpacing) {
                icon
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title.isEmpty ? entry.appName : entry.title)
                        .font(titleFont)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(entry.isMinimized ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                    if !entry.title.isEmpty {
                        Text(entry.appName)
                            .font(subtitleFont)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if entry.isMinimized {
                    Image(systemName: "minus.rectangle")
                        .font(minimizedFont)
                        .foregroundStyle(.secondary)
                        .help("Minimized")
                }
            }
            .padding(.vertical, verticalPad)
            .padding(.horizontal, horizontalPad)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isSelected ? Color.accentColor.opacity(selectedOpacity) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var icon: some View {
        if let img = entry.icon {
            Image(nsImage: img)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
        } else {
            Image(systemName: "macwindow")
                .foregroundStyle(.secondary)
                .frame(width: iconSize, height: iconSize)
        }
    }

    private var iconSize: CGFloat {
        switch style {
        case .compact: return 22
        case .expanded: return 44
        }
    }

    private var titleFont: Font {
        switch style {
        case .compact: return .body
        case .expanded: return .system(size: 16, weight: .medium)
        }
    }

    private var subtitleFont: Font {
        switch style {
        case .compact: return .caption2
        case .expanded: return .callout
        }
    }

    private var minimizedFont: Font {
        switch style {
        case .compact: return .caption
        case .expanded: return .body
        }
    }

    private var innerSpacing: CGFloat {
        switch style {
        case .compact: return 10
        case .expanded: return 14
        }
    }

    private var verticalPad: CGFloat {
        switch style {
        case .compact: return 6
        case .expanded: return 12
        }
    }

    private var horizontalPad: CGFloat {
        switch style {
        case .compact: return 8
        case .expanded: return 14
        }
    }

    private var cornerRadius: CGFloat {
        switch style {
        case .compact: return 6
        case .expanded: return 10
        }
    }

    private var selectedOpacity: Double {
        switch style {
        case .compact: return 0.25
        case .expanded: return 0.28
        }
    }
}
