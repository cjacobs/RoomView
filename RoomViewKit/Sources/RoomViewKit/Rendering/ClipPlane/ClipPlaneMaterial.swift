import RealityKit
import Metal

enum ClipPlaneMaterial {
    private static let library: MTLLibrary = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        do {
            return try device.makeDefaultLibrary(bundle: Bundle.module)
        } catch {
            fatalError("Failed to load ClipPlane.metal library: \(error)")
        }
    }()

    /// Wraps an existing material with a surface shader that discards fragments on
    /// the far side of a world-space plane, preserving the original material's
    /// appearance (base color, textures) on the near side.
    static func makeMaterial(wrapping base: any Material) throws -> CustomMaterial {
        let surfaceShader = CustomMaterial.SurfaceShader(named: "clipPlaneSurfaceShader", in: library)
        return try CustomMaterial(from: base, surfaceShader: surfaceShader)
    }
}
