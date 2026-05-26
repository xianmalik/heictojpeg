import SwiftUI

struct FooterView: View {
    @ObservedObject var model: ConversionModel

    var body: some View {
        HStack(spacing: 12) {
            folderSection
            Spacer()
            actionSection
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        }
    }

    // MARK: - Folder

    private var folderSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(model.outputDirectory != nil ? 0.85 : 0.30))

            if let dir = model.outputDirectory {
                Button { model.revealOutputDirectory() } label: {
                    Text(dir.abbreviatingWithTildeInPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: 220, alignment: .leading)
            } else {
                Text("No output folder")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.30))
                    .frame(maxWidth: 220, alignment: .leading)
            }

            // Choose / Change button — native Liquid Glass
            Button {
                model.chooseOutputDirectory()
            } label: {
                Text(model.outputDirectory == nil ? "Choose…" : "Change…")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
            }
            .buttonStyle(.plain)
            .glassEffect(in: Capsule())
        }
    }

    // MARK: - Actions

    private var actionSection: some View {
        HStack(spacing: 8) {
            if !model.items.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3)) { model.clear() }
                } label: {
                    Text("Clear All")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
                .glassEffect(in: Capsule())
            }

            convertButton
        }
    }

    // MARK: - Convert button

    private var convertButton: some View {
        let n = model.pendingCount
        let label: String = model.isConverting
            ? "Converting…"
            : (n > 0 ? "Convert \(n) \(n == 1 ? "File" : "Files")" : "Convert")

        return Button(action: model.convertAll) {
            HStack(spacing: 6) {
                if model.isConverting {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 12, height: 12)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(label)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .glassEffect(in: Capsule())
        .disabled(!model.canConvert)
        .animation(.easeInOut(duration: 0.18), value: model.canConvert)
        .animation(.easeInOut(duration: 0.18), value: model.isConverting)
    }
}

// MARK: - URL helper

private extension URL {
    var abbreviatingWithTildeInPath: String {
        (self.path as NSString).abbreviatingWithTildeInPath
    }
}
