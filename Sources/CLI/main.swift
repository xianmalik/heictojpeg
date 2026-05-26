import Foundation
import HeicConverter

func printUsage() {
    let name = (CommandLine.arguments.first as NSString?)?.lastPathComponent ?? "heictojpeg"
    print("""
    Usage:
      \(name) <file.heic> [file2.heic ...]          Convert individual files
      \(name) -d <directory> [-o <output-dir>] [-r]  Convert a directory

    Options:
      -d <dir>    Input directory
      -o <dir>    Output directory (default: same as input)
      -r          Recurse into sub-directories
      -q <0-100>  JPEG quality, 0–100 (default: 100)
      -h          Show this help
    """)
}

struct CLIOptions {
    var inputFiles: [URL] = []
    var inputDirectory: URL?
    var outputDirectory: URL?
    var recursive: Bool = false
    var quality: Double = 1.0
}

func parseArgs(_ args: [String]) -> CLIOptions? {
    var opts = CLIOptions()
    var i = 1
    while i < args.count {
        switch args[i] {
        case "-h", "--help":
            printUsage(); return nil
        case "-d":
            i += 1
            guard i < args.count else { fputs("Missing argument for -d\n", stderr); return nil }
            opts.inputDirectory = URL(fileURLWithPath: args[i])
        case "-o":
            i += 1
            guard i < args.count else { fputs("Missing argument for -o\n", stderr); return nil }
            opts.outputDirectory = URL(fileURLWithPath: args[i])
        case "-r":
            opts.recursive = true
        case "-q":
            i += 1
            guard i < args.count, let q = Double(args[i]), (0...100).contains(q) else {
                fputs("Quality must be 0–100\n", stderr); return nil
            }
            opts.quality = q / 100.0
        default:
            opts.inputFiles.append(URL(fileURLWithPath: args[i]))
        }
        i += 1
    }
    return opts
}

guard let opts = parseArgs(CommandLine.arguments) else { exit(0) }

let converter = Converter(quality: opts.quality)
var exitCode: Int32 = 0

if let dir = opts.inputDirectory {
    if let outDir = opts.outputDirectory {
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
    }
    let results = try converter.convertDirectory(at: dir, outputDir: opts.outputDirectory, recursive: opts.recursive)
    if results.isEmpty { print("No HEIC/HEIF files found in \(dir.path)") }
    for result in results {
        switch result {
        case .success(let url): print("✓ \(url.path)")
        case .failure(let error): fputs("✗ \(error.localizedDescription)\n", stderr); exitCode = 1
        }
    }
} else if !opts.inputFiles.isEmpty {
    for fileURL in opts.inputFiles {
        do {
            let out = try converter.convert(fileURL)
            print("✓ \(out.path)")
        } catch {
            fputs("✗ \(error.localizedDescription)\n", stderr)
            exitCode = 1
        }
    }
} else {
    printUsage(); exit(1)
}

exit(exitCode)
