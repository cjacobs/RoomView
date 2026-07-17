import RealityKit
import SwiftUI

/// Applies a clip plane to every material on every `ModelEntity` in an entity
/// hierarchy, keeping the plane perpendicular to the camera's current view
/// direction as it orbits, at an adjustable depth (`threshold`) from the camera.
@MainActor
final class ClipPlaneController {
    private struct Target {
        let entity: ModelEntity
        let materialIndex: Int
    }

    private var targets: [Target] = []
    private var subscription: EventSubscription?
    private weak var camera: Entity?

    /// Distance from the camera, along its view direction, at which geometry
    /// starts being clipped away. 0 clips nothing (full scene visible).
    var threshold: Float = 0

    /// Whether the plane is actively clipping. Disabled while first-person mode
    /// is driving the shared camera, so walking up to geometry doesn't slice it
    /// away the way orbiting-and-approaching would.
    var isEnabled: Bool = true {
        didSet { updatePlaneFromCamera() }
    }

    func apply(to root: Entity) {
        targets.removeAll()
        applyRecursive(root)
    }

    private func applyRecursive(_ entity: Entity) {
        if let modelEntity = entity as? ModelEntity, var model = modelEntity.model {
            for (index, material) in model.materials.enumerated() {
                do {
                    let clipMaterial = try ClipPlaneMaterial.makeMaterial(wrapping: material)
                    model.materials[index] = clipMaterial
                    targets.append(Target(entity: modelEntity, materialIndex: index))
                } catch {
                    print("ClipPlaneController: failed to create clip material: \(error)")
                }
            }
            modelEntity.model = model
        }
        for child in entity.children {
            applyRecursive(child)
        }
    }

    /// Starts keeping the clip plane perpendicular to `camera`'s view direction,
    /// updating every frame so it tracks orbit gestures that RealityKit's camera
    /// controls apply directly to `camera`'s transform.
    func startFollowingCamera(_ camera: Entity, in content: RealityViewCameraContent) {
        self.camera = camera
        subscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            self?.updatePlaneFromCamera()
        }
        updatePlaneFromCamera()
    }

    private func updatePlaneFromCamera() {
        guard isEnabled, let camera else {
            setPlane(normal: SIMD3<Float>(0, 0, 1), offset: .greatestFiniteMagnitude)
            return
        }
        let forward = camera.orientation(relativeTo: nil).act(SIMD3<Float>(0, 0, -1))
        let cameraPosition = camera.position(relativeTo: nil)

        // Discard fragments nearer to the camera than `threshold`, along the
        // view direction: normal = -forward, offset = dot(cameraPosition, normal) - threshold.
        let normal = -forward
        let offset = dot(cameraPosition, normal) - threshold
        setPlane(normal: normal, offset: offset)
    }

    private func setPlane(normal: SIMD3<Float>, offset: Float) {
        for target in targets {
            guard var model = target.entity.model,
                  var material = model.materials[target.materialIndex] as? CustomMaterial else { continue }
            material.custom.value = SIMD4(normal, offset)
            model.materials[target.materialIndex] = material
            target.entity.model = model
        }
    }
}
