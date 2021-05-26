/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders for performing Depth Pre-Pass
*/
#include <metal_stdlib>

using namespace metal;

// Include header shared between this Metal shader code and C code executing Metal API commands
#import "AAPLShaderTypes.h"

// Include header shared between all Metal shader code files
#import "AAPLShaderCommon.h"

struct VertexOutput
{
    float4 position [[position]];
};


// Depth Pre-Pass necessary in forward plus rendering produce a min max depth bounds for light culling

vertex VertexOutput depth_pre_pass_vertex(Vertex in                        [[ stage_in ]],
                                          constant AAPLUniforms & uniforms [[ buffer(AAPLBufferIndexUniforms) ]])
{
    // Make position a float4 to perform 4x4 matrix math on it
    VertexOutput out;
    float4 position = float4(in.position, 1.0);
    
    //Position in clip space
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    
    return out;
}

fragment ColorData depth_pre_pass_fragment(VertexOutput in [[ stage_in ]])
{
    // Fill in on-chip geometry buffer data
    ColorData f;

    // f.lighting=half4(0,0,0,1); // Setting color in depth prepass unnecessary but may make debugging easier
    
    //Depth in clip space that will be used by AAPLCulling to perform per-tile light culling
    f.depth = in.position.z;
    
    return f;
}


