import SwiftUI
import RealityKit

struct SceneContainerView: View {
    let root: Entity
    var clipPlaneController: ClipPlaneController?

    init(root: Entity, clipPlaneController: ClipPlaneController? = nil) {
        self.root = root
        self.clipPlaneController = clipPlaneController
    }

    var body: some View {
        RealityView { content in
            content.add(root)

            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewOrientation = .horizontal
            camera.camera.fieldOfViewInDegrees = 50
            content.add(camera)

            content.camera = .virtual
            content.cameraTarget = root

            clipPlaneController?.startFollowingCamera(camera, in: content)
        }
        .realityViewCameraControls(.orbit)
    }
}
