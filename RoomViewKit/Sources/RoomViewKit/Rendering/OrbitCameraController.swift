import RealityKit
import SwiftUI

/// Adds keyboard-driven orbit rotation (ijkl) around a pivot point, layered on
/// top of RealityKit's built-in drag/pinch `.orbit` camera controls. Recomputes
/// yaw/pitch/radius fresh from the camera's current transform every tick,
/// rather than tracking its own state, so it stays in sync with whatever the
/// built-in drag/pinch gestures did to the camera in between key presses.
@MainActor
final class OrbitCameraController {
    /// x = orbit right, y = orbit up. Set continuously from the ijkl keys.
    var turnInput: SIMD2<Float> = .zero
    var turnSpeed: Float = 1.8

    /// The point the camera orbits around, matching RealityKit's own
    /// `cameraTarget` so keyboard rotation agrees with drag/pinch rotation.
    var pivot: SIMD3<Float> = .zero

    private weak var camera: Entity?
    private var subscription: EventSubscription?

    func start(camera: Entity, in content: RealityViewCameraContent) {
        self.camera = camera
        subscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.tick(deltaTime: Float(event.deltaTime))
        }
    }

    private func tick(deltaTime: Float) {
        guard turnInput != .zero, let camera else { return }

        let offset = camera.position(relativeTo: nil) - pivot
        let radius = length(offset)
        guard radius > 0.0001 else { return }

        let forward = -offset / radius
        let pitch = asin(max(-1, min(1, forward.y)))
        let yaw = atan2(-forward.x, -forward.z)

        var newYaw = yaw - turnInput.x * turnSpeed * deltaTime
        var newPitch = pitch + turnInput.y * turnSpeed * deltaTime
        newPitch = max(-1.4, min(1.4, newPitch))
        newYaw.formTruncatingRemainder(dividingBy: 2 * .pi)

        let newForward = SIMD3<Float>(
            -cos(newPitch) * sin(newYaw),
            sin(newPitch),
            -cos(newPitch) * cos(newYaw)
        )
        camera.position = pivot - newForward * radius
        camera.orientation = simd_quatf(angle: newYaw, axis: [0, 1, 0]) * simd_quatf(angle: newPitch, axis: [1, 0, 0])
    }
}
