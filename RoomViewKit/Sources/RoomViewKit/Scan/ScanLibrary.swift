import Foundation

enum ScanLibrary {
    private static var scansDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("RoomView/Scans", isDirectory: true)
    }

    static func directory(for scanID: UUID) -> URL {
        scansDirectory.appendingPathComponent(scanID.uuidString, isDirectory: true)
    }

    static func usdzURL(for scanID: UUID) -> URL {
        directory(for: scanID).appendingPathComponent("model.usdz")
    }

    static func ensureDirectoryExists(for scanID: UUID) throws {
        try FileManager.default.createDirectory(at: directory(for: scanID), withIntermediateDirectories: true)
    }
}
