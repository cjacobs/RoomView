import SwiftUI
import RealityKit

enum SceneCameraMode {
    case orbit
    case pov
}

struct SceneContainerView: View {
    let root: Entity
    var clipPlaneController: ClipPlaneController?
    var firstPersonController: FirstPersonController?
    var orbitCameraController: OrbitCameraController?
    var cameraMode: SceneCameraMode

    @State private var lastLookDragTranslation: CGSize = .zero

    init(
        root: Entity,
        clipPlaneController: ClipPlaneController? = nil,
        firstPersonController: FirstPersonController? = nil,
        orbitCameraController: OrbitCameraController? = nil,
        cameraMode: SceneCameraMode = .orbit
    ) {
        self.root = root
        self.clipPlaneController = clipPlaneController
        self.firstPersonController = firstPersonController
        self.orbitCameraController = orbitCameraController
        self.cameraMode = cameraMode
    }

    var body: some View {
        realityView
            .realityViewCameraControls(cameraMode == .pov ? .none : .orbit)
            .gesture(lookGesture, isEnabled: cameraMode == .pov)
    }

    private var realityView: some View {
        RealityView { content in
            content.add(root)

            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewOrientation = .horizontal
            camera.camera.fieldOfViewInDegrees = 50
            content.add(camera)

            content.camera = .virtual
            content.cameraTarget = root

            clipPlaneController?.startFollowingCamera(camera, in: content)
            firstPersonController?.start(camera: camera, in: content)
            orbitCameraController?.start(camera: camera, in: content)
        }
    }

    private var lookGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let firstPersonController else { return }
                let delta = CGSize(
                    width: value.translation.width - lastLookDragTranslation.width,
                    height: value.translation.height - lastLookDragTranslation.height
                )
                firstPersonController.applyLookDelta(delta)
                lastLookDragTranslation = value.translation
            }
            .onEnded { _ in
                lastLookDragTranslation = .zero
            }
    }
}
