/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders to cull lights for each tile
*/
#include <metal_stdlib>

using namespace metal;

// Include header shared between this Metal shader code and C code executing Metal API commands
#import "AAPLShaderTypes.h"

// Include header shared between all Metal shader code
#import "AAPLShaderCommon.h"

// Unprojects depth in screensspace giving depth at view space
static float unproject_depth(constant AAPLUniforms &uniforms, float depth)
{
    const float2 depthUnproject = uniforms.depthUnproject;
    return depthUnproject.y / (depth - depthUnproject.x);
}

// Unprojects x and y in screen space to view space if the screen x and y are at screen z = 1.0
static float2 screen_to_view_at_z1(constant AAPLUniforms &uniforms, ushort2 screen)
{
    const float3 screenToViewSpace = uniforms.screenToViewSpace;
    return float2(screen) * float2(screenToViewSpace.x, -screenToViewSpace.x) + float2(screenToViewSpace.y, -screenToViewSpace.z);
}

// Perform per tile culling for lights and writes out list of visible lights into tile memory

// This kernel determines the min and max depth of all geometry rendered to each tile. It then culls
//   each light's volume against the top, bottom, left, and right planes of the tile.
// It also culls each light's volume to the min and max depth that we compute here.  This makes
//   our culling volume even smaller; there is no geometry outside the min and max depth, so if a
//   light's volume is outside that range, we don't need to draw the light.  Consequently, if the
//   min and max depth are the same, there is no geometry in the tile and no volume, so no lights
//   need to be rendered for the tile
kernel void cull_lights(imageblock<ColorData,imageblock_layout_implicit> imageBlock,
                        constant AAPLUniforms &uniforms       [[ buffer(AAPLBufferIndexUniforms) ]],
                        device vector_float4 *light_positions [[ buffer(AAPLBufferIndexLightsPosition)]],
                        threadgroup int *visible_lights       [[ threadgroup(AAPLThreadgroupBufferIndexLightList)]],
                        threadgroup TileData *tile_data       [[ threadgroup(AAPLThreadgroupBufferIndexTileData)]],
                        ushort2 thread_local_position         [[ thread_position_in_threadgroup ]],
                        ushort2 threadgroup_size              [[ threads_per_threadgroup ]],
                        ushort2 threadgroup_id                [[ threadgroup_position_in_grid ]],
                        uint thread_linear_id                 [[ thread_index_in_threadgroup]],
                        uint simd_lane_id                     [[ thread_index_in_quadgroup ]])
{
    ColorData f = imageBlock.read(thread_local_position);

    uint threadgroup_linear_size = threadgroup_size.x*threadgroup_size.y;

    // When the thread group begins...
    if(thread_linear_id == 0)
    {
        // Set our counter for the number of lights in this tile to 0
        atomic_store_explicit(&tile_data->numLights,0,memory_order_relaxed);

        // Initialize our min and max depth values
        tile_data->minDepth = INFINITY;
        tile_data->maxDepth = 0.0;
    }

    // Insert a barrier here before we get the min an max depth for the entire tile to enure
    //   that ALL threads in the threadgroup have determined the min and max depth for their quads
    //   first
    threadgroup_barrier(mem_flags::mem_threadgroup);

    // Determine the min and max depth in our quad group.  Note that quad groups execute in step, so
    //   we can determine the min and max depth value in the quad group without needing to use barriers

    float minDepth = f.depth;
    minDepth = min(minDepth, quad_shuffle_xor(minDepth, 2));
    minDepth = min(minDepth, quad_shuffle_xor(minDepth, 1));

    float maxDepth = f.depth;
    maxDepth = max(maxDepth, quad_shuffle_xor(maxDepth, 2));
    maxDepth = max(maxDepth, quad_shuffle_xor(maxDepth, 1));


    // For one quad lane...
    if (simd_lane_id == 0)
    {
        // ...compare vs everyother depth value in the threadgroups and set it if min depth value
        //   (or max depth value) of the quad  is the min depth value (or max depth value) of the
        //   entire tile
        atomic_fetch_min_explicit((threadgroup atomic_uint *)&tile_data->minDepth, as_type<uint>(minDepth), memory_order_relaxed);
        atomic_fetch_max_explicit((threadgroup atomic_uint *)&tile_data->maxDepth, as_type<uint>(maxDepth), memory_order_relaxed);
    }

    // Ensure our fetch of min/max values of all quad groups withing the thread group hava finished
    //   execution before using the values to test against light volumes
    threadgroup_barrier(mem_flags::mem_threadgroup);

    // Unproject depth from screens space to view/eye space where we do the culling
    float minDepthView = unproject_depth(uniforms, tile_data->minDepth);
    float maxDepthView = unproject_depth(uniforms, tile_data->maxDepth);
    float2 minTileViewAtZ1 = screen_to_view_at_z1(uniforms, threadgroup_id * threadgroup_size);
    float2 maxTileViewAtZ1 = screen_to_view_at_z1(uniforms, (threadgroup_id + 1) * threadgroup_size);

    // Calculate normals of the tile bounding planes
    float3 tile_plane_normal[6];
    tile_plane_normal[0] = normalize(float3(1.0, 0.0, -maxTileViewAtZ1.x)); // right
    tile_plane_normal[1] = normalize(float3(0.0, 1.0, -minTileViewAtZ1.y)); // top
    tile_plane_normal[2] = normalize(float3(-1.0, 0.0, minTileViewAtZ1.x)); // left
    tile_plane_normal[3] = normalize(float3(0.0, -1.0, maxTileViewAtZ1.y)); // bottom
    tile_plane_normal[4] = float3(0.0, 0.0, -1.0); // near
    tile_plane_normal[5] = float3(0.0, 0.0, 1.0);  // far

    // Calculate culling offsets
    float tile_plane_offset[6];

    // Top/Bottom/Right/Left offsets are 0 since center of eye space coordinate system belongs to
    //   all these planes
    tile_plane_offset[0] = 0.0f;
    tile_plane_offset[1] = 0.0f;
    tile_plane_offset[2] = 0.0f;
    tile_plane_offset[3] = 0.0f;

    // Use the min and max depth so we cull light volumes that are completely in front of the nearest
    //   geometry in the tile or completely in back of the furthes geometry in the tile
    tile_plane_offset[4] = -minDepthView;
    tile_plane_offset[5] = maxDepthView;

    // Create list of visible lights inside threadgroup memory
    for (uint baseLightId = 0; baseLightId < AAPLNumLights; baseLightId += threadgroup_linear_size)
    {
        uint32_t visible = 1;

        // Light id for current thread and iteration
        uint lightId = baseLightId+thread_linear_id;
        if(lightId > AAPLNumLights-1)
        {
            visible = 0;
            lightId = 0;
        }

        // Get light data
        float4 light_pos_eye_space = (float4(light_positions[lightId].xyz,1));

        // Cull light against all 6 planes
        for(int j = 0; j < 6; j++)
        {
            if(dot(tile_plane_normal[j],light_pos_eye_space.xyz)-tile_plane_offset[j] > light_positions[lightId].w)
            {
                visible = 0; // separating axis found
                break;
            }
        }

        // Perform stream compaction into tile memory

        // If this light is visible...
        if (visible)
        {
            // Increase the count of lights for this tile and get a slot
            int slot = atomic_fetch_add_explicit(&tile_data->numLights, 1, memory_order_relaxed);

            // Insert the lightId into or visibile light list for this tile
            if (slot < AAPLMaxLightsPerTile)
                visible_lights[slot] = (int)lightId;
        }
    }
}
