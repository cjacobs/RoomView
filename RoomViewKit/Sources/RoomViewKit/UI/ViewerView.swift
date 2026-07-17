import SwiftUI
import RealityKit

struct ViewerView: View {
    let scan: Scan

    @State private var loadedRoot: Entity?
    @State private var loadErrorMessage: String?
    @State private var clipPlaneController = ClipPlaneController()
    @State private var clipThreshold: Float = 0
    @State private var clipRange: ClosedRange<Float> = 0...1

    @State private var firstPersonController = FirstPersonController()
    @State private var cameraMode: SceneCameraMode = .orbit
    @State private var povViewDistance: Float = 0
    @State private var pressedKeys: Set<Character> = []

    private let maxPovViewDistance: Float = 6

    var body: some View {
        Group {
            if let loadedRoot {
                ZStack(alignment: .top) {
                    SceneContainerView(
                        root: loadedRoot,
                        clipPlaneController: clipPlaneController,
                        firstPersonController: firstPersonController,
                        cameraMode: cameraMode
                    )
                    #if os(macOS)
                    .focusable()
                    .onKeyPress(keys: ["w", "a", "s", "d", "i", "j", "k", "l"], phases: [.down, .up]) { press in
                        let key = Character(press.key.character.lowercased())
                        if press.phase == .down {
                            pressedKeys.insert(key)
                        } else if press.phase == .up {
                            pressedKeys.remove(key)
                        }
                        updateInputsFromKeys()
                        return .handled
                    }
                    #endif

                    HStack(alignment: .top) {
                        if cameraMode == .orbit {
                            clipPlaneControl
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

            loadedRoot = entity
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    private func handleModeChange(_ newMode: SceneCameraMode) {
        switch newMode {
        case .pov:
            clipPlaneController.isEnabled = false
            firstPersonController.isDrivingCamera = true
            firstPersonController.syncCameraToAvatar()
        case .orbit:
            firstPersonController.isDrivingCamera = false
            firstPersonController.moveInput = .zero
            firstPersonController.turnInput = .zero
            pressedKeys.removeAll()
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
        firstPersonController.turnInput = SIMD2(turnX, turnY)
    }
    #endif
}
