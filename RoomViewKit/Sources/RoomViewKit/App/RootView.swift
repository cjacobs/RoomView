import SwiftUI
import SwiftData

public struct RootView: View {
    @Query(sort: \Scan.importedAt, order: .reverse) private var scans: [Scan]

    public init() {}

    public var body: some View {
        if let scan = scans.first {
            ViewerView(scan: scan)
        } else {
            ImportView()
        }
    }
}
