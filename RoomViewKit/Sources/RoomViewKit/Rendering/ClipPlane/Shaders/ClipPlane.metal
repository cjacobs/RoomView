#include <RealityKit/RealityKit.h>
#include <metal_stdlib>
using namespace metal;

// Discards fragments on the far side of a world-space plane, letting a scan be
// sliced open to reveal its interior. The plane is passed via CustomMaterial's
// `custom` parameter as (nx, ny, nz, d): fragments with dot(worldPos, n) > d
// are clipped away.
//
// CustomMaterial's surface shader fully replaces shading, so the wrapped
// material's base color texture has to be sampled and applied explicitly or
// every fragment renders plain white.
[[visible]]
void clipPlaneSurfaceShader(realitykit::surface_parameters params)
{
    float3 worldPosition = params.geometry().world_position();
    float4 plane = params.uniforms().custom_parameter();

    float side = dot(worldPosition, plane.xyz) - plane.w;
    if (side > 0.0) {
        discard_fragment();
    }

    constexpr sampler samplerBilinear(coord::normalized,
                                      address::repeat,
                                      filter::linear,
                                      mip_filter::nearest);

    auto tex = params.textures();
    auto surface = params.surface();
    float2 uv = params.geometry().uv0();
    // USD textures require uvs to be flipped.
    uv.y = 1.0 - uv.y;

    half4 colorSample = tex.base_color().sample(samplerBilinear, uv);
    surface.set_base_color(colorSample.rgb * half3(params.material_constants().base_color_tint()));
}
