import SwiftUI
import RealityKit

struct ViewerView: View {
    let scan: Scan

    @State private var loadedRoot: Entity?
    @State private var loadErrorMessage: String?
    @State private var clipPlaneController = ClipPlaneController()
    @State private var clipThreshold: Float = 0
    @State private var clipRange: ClosedRange<Float> = 0...1

    var body: some View {
        Group {
            if let loadedRoot {
                ZStack(alignment: .bottom) {
                    SceneContainerView(root: loadedRoot, clipPlaneController: clipPlaneController)

                    VStack(spacing: 4) {
                        Text("Clip Plane")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $clipThreshold, in: clipRange)
                            .onChange(of: clipThreshold) { _, newValue in
                                clipPlaneController.threshold = newValue
                            }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding()
                }
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
            let entity = try await Entity(contentsOf: ScanLibrary.usdzURL(for: scan.id))

            clipPlaneController.apply(to: entity)
            let bounds = entity.visualBounds(relativeTo: nil)
            clipRange = 0...max(distance(bounds.min, bounds.max), 1)
            clipThreshold = 0
            clipPlaneController.threshold = 0

            loadedRoot = entity
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }
}
