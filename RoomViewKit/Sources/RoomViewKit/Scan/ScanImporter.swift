import Foundation
import SwiftData

@MainActor
enum ScanImporter {
    static func importScan(from sourceURL: URL, into context: ModelContext) throws -> Scan {
        let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let scan = Scan(name: sourceURL.deletingPathExtension().lastPathComponent)
        try ScanLibrary.ensureDirectoryExists(for: scan.id)

        let destination = ScanLibrary.usdzURL(for: scan.id)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)

        context.insert(scan)
        try context.save()
        return scan
    }
}
