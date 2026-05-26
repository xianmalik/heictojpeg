import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var model: ConversionModel
    let isTargeted: Bool

    private var isEmpty: Bool { model.items.isEmpty }

    var body: some View {
        Button(action: openFilePicker) {
            ZStack {
                if isEmpty { emptyContent } else { compactContent }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isEmpty ? 220 : 64)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: isEmpty ? 26 : 18))
            .overlay {
                RoundedRectangle(cornerRadius: isEmpty ? 26 : 18)
                    .strokeBorder(
                        isTargeted ? Color.white.opacity(0.9) : Color.white.opacity(isEmpty ? 0.25 : 0.14),
                        style: StrokeStyle(lineWidth: 1.5, dash: isEmpty ? [9, 6] : [])
                    )
            }
            .scaleEffect(isTargeted && isEmpty ? 1.015 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.80), value: isEmpty)
        .animation(.spring(response: 0.22, dampingFraction: 0.70), value: isTargeted)
    }

    // MARK: - Empty state

    private var emptyContent: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(.white.opacity(isTargeted ? 0.20 : 0.10))
                    .frame(width: 76, height: 76)

                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: isTargeted)
            }
            .animation(.easeInOut(duration: 0.18), value: isTargeted)

            VStack(spacing: 6) {
                Text("Drop HEIC Files Here")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("or click to browse  ·  .heic and .heif")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    // MARK: - Compact state

    private var compactContent: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))

            Text("Add more HEIC files")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))

            Spacer()

            Text("\(model.items.count) file\(model.items.count == 1 ? "" : "s")")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - File picker

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowedContentTypes = [.heic]
        panel.title = "Choose HEIC Files"
        if panel.runModal() == .OK {
            for url in panel.urls {
                if url.hasDirectoryPath { model.addDirectory(url) }
                else { model.addFiles([url]) }
            }
        }
    }
}
