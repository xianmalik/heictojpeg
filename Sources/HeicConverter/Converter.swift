import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum ConversionError: Error, LocalizedError {
    case unreadableSource(URL)
    case cannotCreateDestination(URL)
    case conversionFailed(URL)

    public var errorDescription: String? {
        switch self {
        case .unreadableSource(let url):    return "Cannot read image at \(url.path)"
        case .cannotCreateDestination(let url): return "Cannot create output file at \(url.path)"
        case .conversionFailed(let url):    return "Conversion failed for \(url.path)"
        }
    }
}

public struct Converter: Sendable {
    public let quality: Double

    public init(quality: Double = 1.0) {
        self.quality = max(0, min(1, quality))
    }

    @discardableResult
    public func convert(_ sourceURL: URL, to outputURL: URL? = nil) throws -> URL {
        let destination = outputURL ?? sourceURL
            .deletingPathExtension()
            .appendingPathExtension("jpg")

        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              CGImageSourceGetCount(source) > 0
        else { throw ConversionError.unreadableSource(sourceURL) }

        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ConversionError.unreadableSource(sourceURL)
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let orientation = properties?[kCGImagePropertyOrientation] as? UInt32 ?? 1

        guard let dest = CGImageDestinationCreateWithURL(
            destination as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { throw ConversionError.cannotCreateDestination(destination) }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality,
            kCGImagePropertyOrientation: orientation
        ]
        CGImageDestinationAddImage(dest, cgImage, options as CFDictionary)

        guard CGImageDestinationFinalize(dest) else {
            throw ConversionError.conversionFailed(sourceURL)
        }
        return destination
    }

    public func convertDirectory(
        at inputDir: URL,
        outputDir: URL? = nil,
        recursive: Bool = false
    ) throws -> [Result<URL, Error>] {
        let fm = FileManager.default
        let opts: FileManager.DirectoryEnumerationOptions = recursive ? [] : [.skipsSubdirectoryDescendants]
        guard let enumerator = fm.enumerator(
            at: inputDir,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: opts
        ) else { return [] }

        var results: [Result<URL, Error>] = []
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            guard ext == "heic" || ext == "heif" else { continue }
            let destinationURL: URL? = outputDir.map {
                $0.appendingPathComponent(fileURL.deletingPathExtension().lastPathComponent)
                  .appendingPathExtension("jpg")
            }
            do {
                results.append(.success(try convert(fileURL, to: destinationURL)))
            } catch {
                results.append(.failure(error))
            }
        }
        return results
    }
}
