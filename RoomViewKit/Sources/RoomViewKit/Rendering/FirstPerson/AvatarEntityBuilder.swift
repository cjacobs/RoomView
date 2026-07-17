import RealityKit

@MainActor
enum AvatarEntityBuilder {
    /// A simple marker representing the viewer's position and facing direction:
    /// a body cylinder topped with a sphere "head", plus a small cone "nose"
    /// pointing in the direction the avatar is looking.
    static func buildAvatar() -> Entity {
        let root = Entity()
        root.name = "Avatar"

        let bodyMesh = MeshResource.generateCylinder(height: 1.4, radius: 0.15)
        let bodyMaterial = SimpleMaterial(color: .systemBlue, isMetallic: false)
        let body = ModelEntity(mesh: bodyMesh, materials: [bodyMaterial])
        body.position = [0, 0.7, 0]
        root.addChild(body)

        let headMesh = MeshResource.generateSphere(radius: 0.18)
        let headMaterial = SimpleMaterial(color: .systemBlue, isMetallic: false)
        let head = ModelEntity(mesh: headMesh, materials: [headMaterial])
        head.position = [0, 1.5, 0]
        root.addChild(head)

        let noseMesh = MeshResource.generateCone(height: 0.2, radius: 0.06)
        let noseMaterial = SimpleMaterial(color: .systemRed, isMetallic: false)
        let nose = ModelEntity(mesh: noseMesh, materials: [noseMaterial])
        nose.position = [0, 1.5, -0.2]
        nose.transform.rotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        root.addChild(nose)

        return root
    }
}
