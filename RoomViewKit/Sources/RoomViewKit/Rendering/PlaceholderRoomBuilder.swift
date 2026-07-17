import RealityKit

@MainActor
enum PlaceholderRoomBuilder {
    static func buildRoom() -> Entity {
        let root = Entity()
        root.name = "PlaceholderRoom"

        root.addChild(makeBox(size: [6, 0.1, 6], color: .gray, position: [0, -0.05, 0]))
        root.addChild(makeBox(size: [6, 3, 0.1], color: Material.Color(red: 0.6, green: 0.3, blue: 0.3, alpha: 1), position: [0, 1.5, -3]))
        root.addChild(makeBox(size: [0.1, 3, 6], color: Material.Color(red: 0.3, green: 0.3, blue: 0.6, alpha: 1), position: [-3, 1.5, 0]))
        root.addChild(makeBox(size: [0.1, 3, 6], color: Material.Color(red: 0.3, green: 0.6, blue: 0.3, alpha: 1), position: [3, 1.5, 0]))

        root.addChild(makeBox(size: [0.8, 0.8, 0.8], color: .systemYellow, position: [-1.5, 0.4, -1.5]))
        root.addChild(makeBox(size: [0.5, 1.2, 0.5], color: .systemOrange, position: [1.2, 0.6, -1.8]))
        root.addChild(makeBox(size: [1.0, 0.4, 0.6], color: .systemPurple, position: [0.5, 0.2, 0.8]))

        return root
    }

    private static func makeBox(size: SIMD3<Float>, color: Material.Color, position: SIMD3<Float>) -> ModelEntity {
        let mesh = MeshResource.generateBox(size: size)
        let material = SimpleMaterial(color: color, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = position
        return entity
    }
}
