import SwiftUI
import RealityKit

public struct SceneContainerView: View {
    let root: Entity

    public init(root: Entity) {
        self.root = root
    }

    public var body: some View {
        RealityView { content in
            content.add(root)

            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewOrientation = .horizontal
            camera.camera.fieldOfViewInDegrees = 50
            content.add(camera)

            content.camera = .virtual
            content.cameraTarget = root
        }
        .realityViewCameraControls(.orbit)
    }
}
