import SwiftUI
import RealityKit

public struct SceneContainerView: View {
    public init() {}

    public var body: some View {
        RealityView { content in
            let room = PlaceholderRoomBuilder.buildRoom()
            content.add(room)

            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewOrientation = .horizontal
            camera.camera.fieldOfViewInDegrees = 50
            content.add(camera)

            content.camera = .virtual
            content.cameraTarget = room
        }
        .realityViewCameraControls(.orbit)
    }
}
