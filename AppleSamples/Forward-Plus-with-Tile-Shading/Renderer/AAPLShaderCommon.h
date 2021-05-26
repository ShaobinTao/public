/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header containing types and enum constants shared between Metal shaders (but not C/ObjC source)
*/
#ifndef AAPLShaderCommon_h
#define AAPLShaderCommon_h

// Per-tile data computed by our culling kernel
struct TileData
{
    atomic_int numLights;
    float minDepth;
    float maxDepth;
};

// Per-vertex inputs fed by vertex buffer laid out with MTLVertexDescriptor in Metal API
typedef struct
{
    float3 position [[attribute(AAPLVertexAttributePosition)]];
    float2 texCoord [[attribute(AAPLVertexAttributeTexcoord)]];
    half3 normal    [[attribute(AAPLVertexAttributeNormal)]];
    half3 tangent   [[attribute(AAPLVertexAttributeTangent)]];
    half3 bitangent [[attribute(AAPLVertexAttributeBitangent)]];
} Vertex;

// Outputs for our color attachments
typedef struct
{
    half4 lighting [[color(AAPLRenderTargetLighting)]];
    float depth    [[color(AAPLRenderTargetDepth)]];
} ColorData;

#endif /* AAPLShaderCommon_h */
