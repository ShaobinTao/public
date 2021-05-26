/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header containing types and enum constants shared between Metal shaders and C/ObjC source
*/
#ifndef AAPLShaderTypes_h
#define AAPLShaderTypes_h

#include <simd/simd.h>

// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API buffer set calls
typedef enum AAPLBufferIndices
{
    AAPLBufferIndexMeshPositions     = 0,
    AAPLBufferIndexMeshGenerics      = 1,
    AAPLBufferIndexUniforms          = 2,
    AAPLBufferIndexLightsData        = 3,
    AAPLBufferIndexLightsPosition    = 4
} AAPLBufferIndices;

// Attribute index values shared between shader and C code to ensure Metal shader vertex
//   attribute indices match the Metal API vertex descriptor attribute indices
typedef enum AAPLVertexAttributes
{
    AAPLVertexAttributePosition  = 0,
    AAPLVertexAttributeTexcoord  = 1,
    AAPLVertexAttributeNormal    = 2,
    AAPLVertexAttributeTangent   = 3,
    AAPLVertexAttributeBitangent = 4
} AAPLVertexAttributes;

// Texture index values shared between shader and C code to ensure Metal shader texture indices
//   match indices of Metal API texture set calls
typedef enum AAPLTextureIndices
{
	AAPLTextureIndexBaseColor = 0,
	AAPLTextureIndexSpecular  = 1,
	AAPLTextureIndexNormal    = 2,
    
	AAPLNumTextureIndices
} AAPLTextureIndices;

// Threadgroup space buffer indices
typedef enum AAPLThreadgroupIndices
{
    AAPLThreadgroupBufferIndexLightList  = 0,
    AAPLThreadgroupBufferIndexTileData  = 1,
} AAPLThreadgroupIndices;

typedef enum AAPLRenderTargetIndices
{
    AAPLRenderTargetLighting  = 0,//Required for the procedural blending
    AAPLRenderTargetDepth = 1
} AAPLRenderTargetIndices;

// Structures shared between shader and C code to ensure the layout of uniform data accessed in
//    Metal shaders matches the layout of uniform data set in C code

// Per-light characteristics
typedef struct
{
    vector_float3 lightColor;
    float lightRadius;
    float lightSpeed;
} AAPLPointLight;

// Data constant across all threads, vertices, and fragments
typedef struct
{
    // Per Frame Uniforms
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 projectionMatrixInv;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 viewMatrixInv;
    vector_float2 depthUnproject;
    vector_float3 screenToViewSpace;
    
    // Per Mesh Uniforms
    matrix_float4x4 modelViewMatrix;
    matrix_float3x3 normalMatrix;
    matrix_float4x4 modelMatrix;
    
    // Per Light Properties
    vector_float3 ambientLightColor;
    vector_float3 directionalLightDirection;
    vector_float3 directionalLightColor;
    uint framebufferWidth;
    uint framebufferHeight;
} AAPLUniforms;

// Simple vertex used to render the "fairies"
typedef struct {
    vector_float2 position;
} AAPLSimpleVertex;

#define AAPLNumSamples 4
#define AAPLNumLights 256
#define AAPLMaxLightsPerTile 64
#define AAPLTileWidth 16
#define AAPLTileHeight 16
#define AAPLTileDataSize 256 // size of a on tile structure containing information like tile max depth, tile min depth, lights per tile

#define AAPLThreadgroupBufferSize MAX(AAPLMaxLightsPerTile*sizeof(uint32_t),AAPLTileWidth*AAPLTileHeight*sizeof(uint32_t)) // This buffer is temporary used for depth reduction so needs to be at least width*height*4

#endif /* AAPLShaderTypes_h */

