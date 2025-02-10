//
//  Shaders.metal
//  MetalBilinearFiltering Shared
//
//  Created by JazzG on 8/14/20.
//  Copyright © 2020 JazzG. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

typedef struct
{
    float2 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
} ColorInOut;

vertex ColorInOut vertexShader(Vertex in [[stage_in]])
{
    ColorInOut out;

    out.position = float4(in.position, 0.0, 1.0);
    out.texCoord = in.texCoord;

    return out;
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               texture2d<float> sourceTexture     [[ texture(TextureIndexSource) ]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    float2 adjustedUV = in.texCoord.xy;

    float4 source = sourceTexture.sample(colorSampler, adjustedUV);
    source.yz = adjustedUV;

    return source;


//    return float4(in.position.x, in.position.y, in.texCoord.x, in.texCoord.y);
}
