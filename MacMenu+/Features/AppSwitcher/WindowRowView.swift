import SwiftUI

struct WindowRowView: View {
    let entry: WindowEntry
    let isSelected: Bool
    let onActivate: () -> Void

    init(entry: WindowEntry, isSelected: Bool = false, onActivate: @escaping () -> Void) {
        self.entry = entry
        self.isSelected = isSelected
        self.onActivate = onActivate
    }

    var body: some View {
        Button(action: onActivate) {
            HStack(spacing: 10) {
                icon
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.title.isEmpty ? entry.appName : entry.title)
                        .font(.system(.body))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(entry.isMinimized ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                    if !entry.title.isEmpty {
                        Text(entry.appName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if entry.isMinimized {
                    Image(systemName: "minus.rectangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .help("Minimized")
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.25) : Color.clear)
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
                .frame(width: 22, height: 22)
        } else {
            Image(systemName: "macwindow")
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
        }
    }
}
