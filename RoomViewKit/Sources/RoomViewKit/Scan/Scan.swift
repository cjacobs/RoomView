import Foundation
import SwiftData

@Model
public final class Scan {
    public var id: UUID
    public var name: String
    public var importedAt: Date

    public init(id: UUID = UUID(), name: String, importedAt: Date = .now) {
        self.id = id
        self.name = name
        self.importedAt = importedAt
    }
}
