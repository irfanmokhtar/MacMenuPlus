import SwiftUI

struct ClipboardRowView: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onPin: () -> Void

    var body: some View {
        Button(action: onCopy) {
            HStack(alignment: .top, spacing: 10) {
                icon
                content
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 4) {
                    Button(action: onPin) {
                        Image(systemName: item.isPinned ? "pin.fill" : "pin")
                            .foregroundStyle(item.isPinned ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.tertiary))
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    Text(item.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(item.isPinned ? "Unpin" : "Pin", action: onPin)
            Button("Copy", action: onCopy)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }

    @ViewBuilder private var icon: some View {
        switch item.payload {
        case .text:
            Image(systemName: "text.alignleft")
                .foregroundStyle(.secondary)
                .frame(width: 20)
        case .image(let img):
            Image(nsImage: img)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    @ViewBuilder private var content: some View {
        switch item.payload {
        case .text(let s):
            Text(s)
                .font(.system(.body, design: .default))
                .lineLimit(2)
                .truncationMode(.tail)
        case .image(let img):
            VStack(alignment: .leading, spacing: 2) {
                Text("Image")
                    .font(.body)
                Text("\(Int(img.size.width)) × \(Int(img.size.height))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
