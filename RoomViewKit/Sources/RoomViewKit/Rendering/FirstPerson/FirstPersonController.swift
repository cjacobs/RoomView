import RealityKit
import SwiftUI

/// Drives a walkable avatar: WASD/joystick movement, drag-to-look, and (while
/// active) keeps a camera entity synced to the avatar's eye position each frame.
@MainActor
final class FirstPersonController {
    let avatarEntity: Entity

    private(set) var position: SIMD3<Float>
    private(set) var yaw: Float = 0
    private(set) var pitch: Float = 0

    /// x = strafe right, y = forward. Set continuously from WASD or a joystick.
    var moveInput: SIMD2<Float> = .zero
    var moveSpeed: Float = 1.6

    /// x = turn right, y = look up. Set continuously from the ijkl keys.
    var turnInput: SIMD2<Float> = .zero
    var turnSpeed: Float = 1.8

    var lookSensitivity: Float = 0.005
    var eyeHeight: Float = 1.6

    /// How far the camera sits behind the eye position along the current view
    /// vector. 0 is true first-person; positive values pull the camera back
    /// while keeping the same view direction, for a "zoomed out" POV.
    var viewDistance: Float = 0

    private weak var camera: Entity?
    private var subscription: EventSubscription?

    init(startPosition: SIMD3<Float> = .zero) {
        self.position = startPosition
        self.avatarEntity = AvatarEntityBuilder.buildAvatar()
        updateAvatarTransform()
    }

    /// Begins a per-frame update loop that moves the avatar from `moveInput`
    /// and, while `isDrivingCamera` is true, keeps `camera` synced to it.
    func start(camera: Entity, in content: RealityViewCameraContent) {
        self.camera = camera
        subscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.tick(deltaTime: Float(event.deltaTime))
        }
    }

    /// Whether the camera should follow the avatar this frame. Set to false
    /// while in orbit/cutaway mode. Toggling this saves/restores the camera's
    /// prior transform, so switching back to orbit resumes exactly where the
    /// orbit camera was left rather than wherever POV last put it (e.g. pulled
    /// back by `viewDistance`).
    var isDrivingCamera: Bool = false {
        didSet {
            guard isDrivingCamera != oldValue, let camera else { return }
            if isDrivingCamera {
                savedTransform = camera.transform
            } else if let savedTransform {
                camera.transform = savedTransform
            }
        }
    }

    private var savedTransform: Transform?

    func applyLookDelta(_ delta: CGSize) {
        yaw -= Float(delta.width) * lookSensitivity
        pitch -= Float(delta.height) * lookSensitivity
        pitch = max(-1.4, min(1.4, pitch))
    }

    /// Snaps the camera to the avatar immediately, e.g. right after switching
    /// into first-person mode, rather than waiting for the next frame tick.
    func syncCameraToAvatar() {
        updateCameraTransform()
    }

    /// Repositions the avatar directly, e.g. to a scan's floor center right
    /// after it loads, without animating through `moveInput`.
    func warp(to newPosition: SIMD3<Float>, yaw newYaw: Float = 0) {
        position = newPosition
        yaw = newYaw
        updateAvatarTransform()
        if isDrivingCamera {
            updateCameraTransform()
        }
    }

    private func tick(deltaTime: Float) {
        let yawRotation = simd_quatf(angle: yaw, axis: [0, 1, 0])
        let forward = yawRotation.act(SIMD3<Float>(0, 0, -1))
        let right = yawRotation.act(SIMD3<Float>(1, 0, 0))
        position += (right * moveInput.x + forward * moveInput.y) * moveSpeed * deltaTime

        yaw -= turnInput.x * turnSpeed * deltaTime
        pitch += turnInput.y * turnSpeed * deltaTime
        pitch = max(-1.4, min(1.4, pitch))

        updateAvatarTransform()
        if isDrivingCamera {
            updateCameraTransform()
        }
    }

    private func updateAvatarTransform() {
        avatarEntity.position = position
        avatarEntity.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
    }

    private func updateCameraTransform() {
        guard let camera else { return }
        let orientation = simd_quatf(angle: yaw, axis: [0, 1, 0]) * simd_quatf(angle: pitch, axis: [1, 0, 0])
        let eyePosition = position + SIMD3<Float>(0, eyeHeight, 0)
        let forward = orientation.act(SIMD3<Float>(0, 0, -1))
        camera.position = eyePosition - forward * viewDistance
        camera.orientation = orientation
    }
}
