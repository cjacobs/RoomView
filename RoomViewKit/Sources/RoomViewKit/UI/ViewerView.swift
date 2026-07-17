import SwiftUI
import RealityKit

struct ViewerView: View {
    let scan: Scan

    @State private var loadedRoot: Entity?
    @State private var loadErrorMessage: String?

    var body: some View {
        Group {
            if let loadedRoot {
                SceneContainerView(root: loadedRoot)
            } else if let loadErrorMessage {
                VStack(spacing: 8) {
                    Text("Failed to load scan")
                        .font(.headline)
                    Text(loadErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                ProgressView("Loading scan…")
            }
        }
        .task(id: scan.id) {
            await loadScan()
        }
    }

    private func loadScan() async {
        loadedRoot = nil
        loadErrorMessage = nil
        do {
            loadedRoot = try await Entity(contentsOf: ScanLibrary.usdzURL(for: scan.id))
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }
}
