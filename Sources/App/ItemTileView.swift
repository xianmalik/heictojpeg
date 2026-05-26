import SwiftUI

struct ItemTileView: View {
    let item: ConversionItem
    let onRemove: () -> Void

    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                thumbnailArea
                infoRow
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.28), radius: 12, y: 6)
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .brightness(isHovered ? 0.05 : 0)

            if isHovered, case .pending = item.status {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.55))
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
                .padding(6)
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isHovered)
    }

    // MARK: - Thumbnail

    private var thumbnailArea: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let thumb = item.thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(.white.opacity(0.06))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                }
            }
            .frame(height: 140)
            .clipped()
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 16
                )
            )

            statusBadge.padding(8)
        }
    }

    // MARK: - Info row

    private var infoRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.fileName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.white.opacity(0.9))

                if !item.fileSize.isEmpty {
                    Text(item.fileSize)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.42))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
    }

    // MARK: - Status badge

    @ViewBuilder
    private var statusBadge: some View {
        switch item.status {
        case .pending:
            EmptyView()

        case .converting:
            ProgressView()
                .controlSize(.small)
                .tint(.white)
                .padding(7)
                .background(.ultraThinMaterial, in: Circle())

        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .green)
                .font(.system(size: 24, weight: .bold))
                .shadow(color: .green.opacity(0.7), radius: 8)

        case .failed(let msg):
            Image(systemName: "exclamationmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .red)
                .font(.system(size: 24, weight: .bold))
                .shadow(color: .red.opacity(0.7), radius: 8)
                .help(msg)
        }
    }
}
