//
//  Shaders.metal
//  VertexAmplification Shared
//
//  Created by monterey on 2/28/22.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

typedef struct
{
    float3 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
    ushort viewport [[viewport_array_index]]; // Implicitly shared.
} ColorInOut;

vertex ColorInOut vertexShader(Vertex in [[stage_in]],
                               ushort amp_id [[amplification_id]],
                               ushort amp_count [[amplification_count]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    ColorInOut out;

    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.texCoord = in.texCoord;
    out.viewport = 0;

    return out;
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               ushort amp_id [[amplification_id]],
                               ushort amp_count [[amplification_count]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]],
                               texture2d<half> colorMap     [[ texture(TextureIndexColor) ]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    half4 colorSample   = colorMap.sample(colorSampler, in.texCoord.xy);

    return float4(colorSample);
}
