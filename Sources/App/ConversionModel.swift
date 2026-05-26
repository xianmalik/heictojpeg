import Foundation
import AppKit
import ImageIO
import HeicConverter

// MARK: - Item

struct ConversionItem: Identifiable {
    let id = UUID()
    let sourceURL: URL
    var status: Status = .pending
    var thumbnail: NSImage?

    enum Status {
        case pending, converting, completed(URL), failed(String)
    }

    var fileName: String { sourceURL.deletingPathExtension().lastPathComponent }

    var fileSize: String {
        guard let size = try? sourceURL.resourceValues(forKeys: [.fileSizeKey]).fileSize else { return "" }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

// MARK: - ViewModel

@MainActor
final class ConversionModel: ObservableObject {
    @Published var items: [ConversionItem] = []
    @Published var outputDirectory: URL?
    @Published var isConverting = false
    @Published var showCompletionAlert = false
    private(set) var lastConversionResult: (succeeded: Int, failed: Int) = (0, 0)

    var canConvert: Bool {
        !isConverting && outputDirectory != nil && items.contains {
            if case .pending = $0.status { return true }
            return false
        }
    }

    var pendingCount: Int {
        items.filter { if case .pending = $0.status { return true }; return false }.count
    }

    var completedCount: Int {
        items.filter { if case .completed = $0.status { return true }; return false }.count
    }

    // MARK: - File management

    func addFiles(_ urls: [URL]) {
        let existing = Set(items.map { $0.sourceURL })
        let newItems = urls
            .filter { ["heic", "heif"].contains($0.pathExtension.lowercased()) }
            .filter { !existing.contains($0) }
            .map { ConversionItem(sourceURL: $0) }

        items.append(contentsOf: newItems)

        for item in newItems {
            let id = item.id
            let url = item.sourceURL
            Task {
                let thumb = await makeThumbnail(url: url)
                if let i = items.firstIndex(where: { $0.id == id }) {
                    items[i].thumbnail = thumb
                }
            }
        }
    }

    func addDirectory(_ url: URL) {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        let urls = (enumerator.allObjects as? [URL]) ?? []
        addFiles(urls)
    }

    func remove(id: UUID) { items.removeAll { $0.id == id } }
    func clear() { items.removeAll() }

    // MARK: - Conversion

    func convertAll() {
        guard let outputDir = outputDirectory else { return }
        isConverting = true

        Task {
            let pending = items.filter { if case .pending = $0.status { return true }; return false }
            let ids = pending.map { $0.id }
            let sources = pending.map { $0.sourceURL }

            await withTaskGroup(of: Void.self) { group in
                for (itemID, sourceURL) in zip(ids, sources) {
                    let destURL = outputDir
                        .appendingPathComponent(sourceURL.deletingPathExtension().lastPathComponent)
                        .appendingPathExtension("jpg")

                    group.addTask { @MainActor [weak self] in
                        guard let self else { return }
                        if let i = self.items.firstIndex(where: { $0.id == itemID }) {
                            self.items[i].status = .converting
                        }

                        do {
                            let result = try await Task.detached(priority: .userInitiated) {
                                try Converter(quality: 1.0).convert(sourceURL, to: destURL)
                            }.value
                            if let i = self.items.firstIndex(where: { $0.id == itemID }) {
                                self.items[i].status = .completed(result)
                            }
                        } catch {
                            if let i = self.items.firstIndex(where: { $0.id == itemID }) {
                                self.items[i].status = .failed(error.localizedDescription)
                            }
                        }
                    }
                }
            }

            let succeeded = items.filter { if case .completed = $0.status { return true }; return false }.count
            let failed = items.filter { if case .failed = $0.status { return true }; return false }.count
            lastConversionResult = (succeeded, failed)
            isConverting = false
            showCompletionAlert = true
        }
    }

    // MARK: - Directory picker

    func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Select Folder"
        panel.message = "Converted JPEG files will be saved here"
        if panel.runModal() == .OK {
            outputDirectory = panel.url
        }
    }

    func revealOutputDirectory() {
        guard let dir = outputDirectory else { return }
        NSWorkspace.shared.open(dir)
    }

    // MARK: - Thumbnail

    private func makeThumbnail(url: URL) async -> NSImage? {
        let cgImage = await Task.detached(priority: .background) { () -> CGImage? in
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let opts: [CFString: Any] = [
                kCGImageSourceThumbnailMaxPixelSize: 300,
                kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
            ]
            return CGImageSourceCreateThumbnailAtIndex(source, 0, opts as CFDictionary)
        }.value
        guard let cg = cgImage else { return nil }
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }
}
