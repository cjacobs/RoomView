import SwiftUI
import RealityKit
import UniformTypeIdentifiers

struct ViewerView: View {
    let scan: Scan

    @Environment(\.modelContext) private var modelContext

    @State private var loadedRoot: Entity?
    @State private var loadErrorMessage: String?
    @State private var clipPlaneController = ClipPlaneController()
    @State private var clipThreshold: Float = 0
    @State private var clipRange: ClosedRange<Float> = 0...1

    @State private var firstPersonController = FirstPersonController()
    @State private var orbitCameraController = OrbitCameraController()
    @State private var cameraMode: SceneCameraMode = .orbit
    @State private var povViewDistance: Float = 0
    @State private var pressedKeys: Set<Character> = []

    @State private var isImporterPresented = false
    @State private var importErrorMessage: String?

    private let maxPovViewDistance: Float = 6

    var body: some View {
        Group {
            if let loadedRoot {
                ZStack(alignment: .top) {
                    SceneContainerView(
                        root: loadedRoot,
                        clipPlaneController: clipPlaneController,
                        firstPersonController: firstPersonController,
                        orbitCameraController: orbitCameraController,
                        cameraMode: cameraMode
                    )
                    #if os(macOS)
                    .focusable()
                    .onKeyPress(keys: ["w", "a", "s", "d", "i", "j", "k", "l"], phases: [.down, .up, .repeat]) { press in
                        let key = Character(press.key.character.lowercased())
                        if press.phase == .down || press.phase == .repeat {
                            pressedKeys.insert(key)
                        } else if press.phase == .up {
                            pressedKeys.remove(key)
                        }
                        updateInputsFromKeys()
                        return .handled
                    }
                    #endif

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            importButton
                            if cameraMode == .orbit {
                                clipPlaneControl
                            }
                        }
                        Spacer()
                        modeControls
                    }
                    .padding(8)

                    #if os(iOS)
                    if cameraMode == .pov {
                        VStack {
                            Spacer()
                            HStack {
                                JoystickView(vector: $firstPersonController.moveInput)
                                Spacer()
                            }
                        }
                        .padding(12)
                    }
                    #endif
                }
                .onChange(of: cameraMode) { _, newMode in
                    handleModeChange(newMode)
                }
                .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.usdz]) { result in
                    switch result {
                    case .success(let url):
                        do {
                            _ = try ScanImporter.importScan(from: url, into: modelContext)
                        } catch {
                            importErrorMessage = "Import failed: \(error.localizedDescription)"
                        }
                    case .failure(let error):
                        importErrorMessage = error.localizedDescription
                    }
                }
                .alert(
                    "Import Failed",
                    isPresented: Binding(
                        get: { importErrorMessage != nil },
                        set: { if !$0 { importErrorMessage = nil } }
                    )
                ) {
                    Button("OK") { importErrorMessage = nil }
                } message: {
                    Text(importErrorMessage ?? "")
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

    private var importButton: some View {
        Button {
            importErrorMessage = nil
            isImporterPresented = true
        } label: {
            Image(systemName: "plus")
                .font(.body)
                .padding(8)
        }
        .buttonStyle(.plain)
        .background(.ultraThinMaterial, in: Circle())
    }

    private var clipPlaneControl: some View {
        HStack(spacing: 6) {
            Text("Clip")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Slider(value: $clipThreshold, in: clipRange)
                .onChange(of: clipThreshold) { _, newValue in
                    clipPlaneController.threshold = newValue
                }
                .frame(width: 120)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var modeControls: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Picker("Mode", selection: $cameraMode) {
                Text("Orbit").tag(SceneCameraMode.orbit)
                Text("POV").tag(SceneCameraMode.pov)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 120)

            if cameraMode == .pov {
                HStack(spacing: 6) {
                    Text("Zoom")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Slider(value: $povViewDistance, in: 0...maxPovViewDistance)
                        .onChange(of: povViewDistance) { _, newValue in
                            firstPersonController.viewDistance = newValue
                        }
                }
                .frame(width: 160)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
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

            let floorCenter = SIMD3<Float>(
                (bounds.min.x + bounds.max.x) / 2,
                bounds.min.y,
                (bounds.min.z + bounds.max.z) / 2
            )
            firstPersonController.warp(to: floorCenter)
            orbitCameraController.pivot = (bounds.min + bounds.max) / 2

            loadedRoot = entity
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    private func handleModeChange(_ newMode: SceneCameraMode) {
        pressedKeys.removeAll()
        orbitCameraController.turnInput = .zero
        switch newMode {
        case .pov:
            clipPlaneController.isEnabled = false
            firstPersonController.isDrivingCamera = true
            firstPersonController.syncCameraToAvatar()
        case .orbit:
            firstPersonController.isDrivingCamera = false
            firstPersonController.moveInput = .zero
            firstPersonController.turnInput = .zero
            clipPlaneController.isEnabled = true
        }
    }

    #if os(macOS)
    private func updateInputsFromKeys() {
        var moveX: Float = 0
        var moveY: Float = 0
        if pressedKeys.contains("d") { moveX += 1 }
        if pressedKeys.contains("a") { moveX -= 1 }
        if pressedKeys.contains("w") { moveY += 1 }
        if pressedKeys.contains("s") { moveY -= 1 }
        firstPersonController.moveInput = SIMD2(moveX, moveY)

        var turnX: Float = 0
        var turnY: Float = 0
        if pressedKeys.contains("l") { turnX += 1 }
        if pressedKeys.contains("j") { turnX -= 1 }
        if pressedKeys.contains("i") { turnY += 1 }
        if pressedKeys.contains("k") { turnY -= 1 }
        let turnInput = SIMD2<Float>(turnX, turnY)
        switch cameraMode {
        case .pov:
            firstPersonController.turnInput = turnInput
            orbitCameraController.turnInput = .zero
        case .orbit:
            orbitCameraController.turnInput = turnInput
            firstPersonController.turnInput = .zero
        }
    }
    #endif
}
