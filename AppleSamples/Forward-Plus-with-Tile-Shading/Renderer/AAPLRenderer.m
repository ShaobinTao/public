/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of renderer class which perfoms Metal setup and per frame rendering
*/
@import simd;
@import ModelIO;
@import MetalKit;

#import "AAPLRenderer.h"
#import "AAPLMesh.h"
#import "AAPLMathUtilities.h"

// Include header shared between C code here, which executes Metal API commands, and .metal files
#import "AAPLShaderTypes.h"

// The max number of command buffers in flight
static const NSUInteger AAPLMaxBuffersInFlight = 3;

// Number of vertices in our fairy model
static const NSUInteger AAPLNumFairyVertices = 7;

// Generates random float value inside given range
inline static float random_float(float min, float max) { return (((double)rand()/RAND_MAX) * (max-min)) + min; }

// Main class performing the rendering
@implementation AAPLRenderer
{
    dispatch_semaphore_t _inFlightSemaphore;
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;

    // Vertex descriptor for models loaded with MetalKit and used for render pipelines
    MTLVertexDescriptor *_defaultVertexDescriptor;

    // Pipeline states
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLRenderPipelineState> _depthPrePassPipelineState;
    id <MTLRenderPipelineState> _lightCullingPipelineState;
    id <MTLRenderPipelineState> _lightResolvePipelineState;
    id <MTLRenderPipelineState> _forwardLightingPipelineState;
    id <MTLRenderPipelineState> _fairyPipelineState;

    // Depth states
    id <MTLDepthStencilState> _defaultDepthState;
    id <MTLDepthStencilState> _relaxedDepthState;
    id <MTLDepthStencilState> _dontWriteDepthState;

    id <MTLTexture> _depthData;

    // Buffers used to store dynamically changing per frame data
    id <MTLBuffer> _uniformBuffers[AAPLMaxBuffersInFlight];

    // Buffers used to story dynamically changing light positions
    id <MTLBuffer> _lightWorldPositions[AAPLMaxBuffersInFlight];
    id <MTLBuffer> _lightEyePositions[AAPLMaxBuffersInFlight];

    // Current buffer to fill with dynamic uniform data and set for the current frame
    uint8_t _currentBufferIndex;

    // Buffer for constant light data
    id <MTLBuffer> _lightsData;

    // Field of view used to create perspective projection (In Radians)
    float _fov;

    // Near depth plane for projection matrix
    float _nearPlane;

    // Far depth plane for projection matrix
    float _farPlane;

    // Projection matrix calculated as a function of view size
    matrix_float4x4 _projectionMatrix;
    // Current rotation of our object in radians
    float _rotation;

	// Array of App-Specific mesh objects in our scene
    NSArray<AAPLMesh *> *_meshes;

    // Mesh buffer for fairies
    id<MTLBuffer> _fairy;
}

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
{
    self = [super init];
    if(self)
    {
        _device = view.device;

        if(![_device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily4_v1])
        {
            // This sample requires APIs avaliable with the iOS_GPUFamily4_v1 feature set
            //   (which is avaliable on devices with A11 GPUs or later).  If the iOS_GPUFamily4_v1
            //   feature set is is unavliable, the app would need to implement a backup path that
            //   does not use many of the APIs demonstated in this sample.  However, the
            //   implementation of such a backup path is beyond the scope of this sample.
            assert(!"Sample requires GPUFamily4_v1 (introduced with A11)");
            return nil;
        }

        _inFlightSemaphore = dispatch_semaphore_create(AAPLMaxBuffersInFlight);
        [self loadMetalWithMetalKitView:view];
        [self loadAssets];
        [self populateLights];
    }

    return self;
}

/// Create Metal render state objects
- (void)loadMetalWithMetalKitView:(nonnull MTKView *)view
{
    // Create and load our basic Metal state objects

    // Load all the shader files with a metal file extension in the project
    id <MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

    // Create and allocate our uniform buffer objects.
    for(NSUInteger i = 0; i < AAPLMaxBuffersInFlight; i++)
    {
        // Indicate shared storage so that both the  CPU can access the buffers
        const MTLResourceOptions storageMode = MTLResourceStorageModeShared;

        _uniformBuffers[i] = [_device newBufferWithLength:sizeof(AAPLUniforms)
                                                  options:storageMode];

        _uniformBuffers[i].label = [NSString stringWithFormat:@"UniformBuffer%lu", i];

        _lightWorldPositions[i] = [_device newBufferWithLength:sizeof(vector_float4)*AAPLNumLights
                                                  options:storageMode];

        _lightWorldPositions[i].label = [NSString stringWithFormat:@"LightPositions%lu", i];

        _lightEyePositions[i] = [_device newBufferWithLength:sizeof(vector_float4)*AAPLNumLights
                                                          options:storageMode];

        _lightEyePositions[i].label = [NSString stringWithFormat:@"LightPositionsEyeSpace%lu", i];
    }

    // Create a vertex descriptor for our Metal pipeline. Specifies the layout of vertices the
    //   pipeline should expect.  The layout below keeps attributes used to calculate vertex shader
    //   output position separate (world position, skinning, tweening weights) separate from other
    //   attributes (texture coordinates, normals).  This generally maximizes pipeline efficiency

    _defaultVertexDescriptor = [[MTLVertexDescriptor alloc] init];

    // Positions.
    _defaultVertexDescriptor.attributes[AAPLVertexAttributePosition].format = MTLVertexFormatFloat3;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributePosition].offset = 0;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributePosition].bufferIndex = AAPLBufferIndexMeshPositions;

    // Texture coordinates.
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].format = MTLVertexFormatFloat2;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].offset = 0;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Normals.
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeNormal].format = MTLVertexFormatHalf4;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeNormal].offset = 8;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeNormal].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Tangents
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTangent].format = MTLVertexFormatHalf4;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTangent].offset = 16;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTangent].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Bitangents
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeBitangent].format = MTLVertexFormatHalf4;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeBitangent].offset = 24;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeBitangent].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Position Buffer Layout
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stride = 12;
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stepRate = 1;
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;

    // Generic Attribute Buffer Layout
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stride = 32;
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stepRate = 1;
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;

    view.contentScaleFactor = [UIScreen mainScreen].nativeScale;  // Use native resolution of display
    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    view.sampleCount = AAPLNumSamples;

    // Creating render pipeline state descriptor
    MTLRenderPipelineDescriptor * renderPipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];

    renderPipelineStateDescriptor.sampleCount = view.sampleCount;
    renderPipelineStateDescriptor.vertexDescriptor = _defaultVertexDescriptor;
    renderPipelineStateDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = view.colorPixelFormat;
    renderPipelineStateDescriptor.colorAttachments[AAPLRenderTargetDepth].pixelFormat = MTLPixelFormatR32Float;
    renderPipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
    renderPipelineStateDescriptor.stencilAttachmentPixelFormat = view.depthStencilPixelFormat;

    // Setting unique descriptor values for Depth Pre-Pass  pipeline state
    {
        NSError* error;
        // Load the fragment function into the library
        id <MTLFunction> depthPrePassVertexFunction = [defaultLibrary newFunctionWithName:@"depth_pre_pass_vertex"];
        id <MTLFunction> depthPrePassFragmentFunction = [defaultLibrary newFunctionWithName:@"depth_pre_pass_fragment"];
        renderPipelineStateDescriptor.label = @"Depth Pre-Pass";
        renderPipelineStateDescriptor.vertexDescriptor = _defaultVertexDescriptor;
        renderPipelineStateDescriptor.vertexFunction = depthPrePassVertexFunction;
        renderPipelineStateDescriptor.fragmentFunction = depthPrePassFragmentFunction;

        _depthPrePassPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineStateDescriptor
                                                                         error:&error];
        if (!_depthPrePassPipelineState) {
            NSLog(@"Failed to created pipeline state, error %@", error);
        }
    }

    // Setting unique descriptor values for standard material pipeline state
    {
        NSError* error;
        id <MTLFunction> vertexStandardMaterial = [defaultLibrary newFunctionWithName:@"forward_lighting_vertex"];
        id <MTLFunction> fragmentStandardMaterial = [defaultLibrary newFunctionWithName:@"forward_lighting_fragment"];

        renderPipelineStateDescriptor.label = @"Forward Lighting";
        renderPipelineStateDescriptor.vertexDescriptor = _defaultVertexDescriptor;
        renderPipelineStateDescriptor.vertexFunction = vertexStandardMaterial;
        renderPipelineStateDescriptor.fragmentFunction = fragmentStandardMaterial;
        _forwardLightingPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineStateDescriptor
                                                                                 error:&error];
        if (!_forwardLightingPipelineState) {
            NSLog(@"Failed to created pipeline state, error %@", error);
        }
    }

    // Setting unique descriptor values for fairy pipeline state
    {
        NSError *error;
        id <MTLFunction> fairyVertexFunction = [defaultLibrary newFunctionWithName:@"fairy_vertex"];
        id <MTLFunction> fairyFragmentFunction = [defaultLibrary newFunctionWithName:@"fairy_fragment"];

        renderPipelineStateDescriptor.label = @"Fairy";
        renderPipelineStateDescriptor.vertexDescriptor = nil;
        renderPipelineStateDescriptor.vertexFunction = fairyVertexFunction;
        renderPipelineStateDescriptor.fragmentFunction = fairyFragmentFunction;
        _fairyPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineStateDescriptor
                                                                      error:&error];
        if (!_fairyPipelineState) {
            NSLog(@"Failed to created pipeline state, error %@", error);
        }
    }
    
    // Creating tile render pipeline state descriptor for culling pipelin
    {
        NSError *error;

        id <MTLFunction> lightCullingKernel = [defaultLibrary newFunctionWithName:@"cull_lights"];

        MTLTileRenderPipelineDescriptor *tileRenderPipelineDescriptor = [MTLTileRenderPipelineDescriptor new];
        tileRenderPipelineDescriptor.label = @"Light Culling";
        tileRenderPipelineDescriptor.rasterSampleCount = AAPLNumSamples;
        tileRenderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = view.colorPixelFormat;
        tileRenderPipelineDescriptor.colorAttachments[AAPLRenderTargetDepth].pixelFormat = MTLPixelFormatR32Float;
        tileRenderPipelineDescriptor.threadgroupSizeMatchesTileSize = YES;
        tileRenderPipelineDescriptor.tileFunction = lightCullingKernel;
        _lightCullingPipelineState = [_device newRenderPipelineStateWithTileDescriptor:tileRenderPipelineDescriptor
                                                                               options:0 reflection:nil error:&error];
        if (!_lightCullingPipelineState) {
            NSLog(@"Failed to create pipeline state, error %@", error);
        }
    }

    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];

    // Creating depth state with depth buffer write enabled
    {
        // Note that here we use "LESS" because we're rendering on a "clean" depth buffer
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
        depthStateDesc.depthWriteEnabled = YES;
        _defaultDepthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    }

    // Creating depth state with depth buffer write disabled and test set to LessEqual
    {
        // Note here that the comparison is LESS OR EQUAL instead of LESS.
        // The geometry pass renders to a pre-populated depth buffer (Depth-Prepass) so each
        //   fragment nees to pass if its Z-value is equal to the existing value already in the
        //   depth buffer
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
        depthStateDesc.depthWriteEnabled = NO;
        _relaxedDepthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    }

    // Creating depth state with depth buffer write disabled
    {
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
        depthStateDesc.depthWriteEnabled = NO;
        _dontWriteDepthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    }

    // Create the command queue
    _commandQueue = [_device newCommandQueue];
}

// Load models/textures, etc.
- (void)loadAssets
{
	// Create and load our assets into Metal objects including meshes and textures
	NSError *error = nil;

    // Creata a ModelIO vertexDescriptor so that we format/layout our ModelIO mesh vertices to
    //   fit our Metal render pipeline's vertex descriptor layout
    MDLVertexDescriptor *modelIOVertexDescriptor =
        MTKModelIOVertexDescriptorFromMetal(_defaultVertexDescriptor);

    // Indicate how each Metal vertex descriptor attribute maps to each ModelIO  attribute
    modelIOVertexDescriptor.attributes[AAPLVertexAttributePosition].name  = MDLVertexAttributePosition;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].name  = MDLVertexAttributeTextureCoordinate;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeNormal].name    = MDLVertexAttributeNormal;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeTangent].name   = MDLVertexAttributeTangent;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeBitangent].name = MDLVertexAttributeBitangent;

    NSURL *modelFileURL = [[NSBundle mainBundle] URLForResource:@"Meshes/Temple.obj" withExtension:nil];

    if(!modelFileURL)
    {
        NSLog(@"Could not find model (%@) file in bundle",
              modelFileURL.absoluteString);
    }

    _meshes = [AAPLMesh newMeshesFromURL:modelFileURL
                 modelIOVertexDescriptor:modelIOVertexDescriptor
                             metalDevice:_device
                                   error:&error];
    if(!_meshes || error)
    {
        NSLog(@"Could not create meshes from model file %@", modelFileURL.absoluteString);
    }

    _lightsData = [_device newBufferWithLength:sizeof(AAPLPointLight)*AAPLNumLights options:0];
    _lightsData.label = @"LightData";
    if(!_lightsData)
    {
        NSLog(@"Could not create lights data buffer");
    }

    // Create a simple 2D triangle strip circle mesh for our fairies
    {
        static const float FairySize = 2.5;
        AAPLSimpleVertex fairyVertices[AAPLNumFairyVertices];
        const float angle = 2*M_PI/(float)AAPLNumFairyVertices;
        for(int vtx = 0; vtx < AAPLNumFairyVertices; vtx++)
        {
            int point = (vtx%2) ? (vtx+1)/2 : -vtx/2;
            fairyVertices[vtx].position =  (vector_float2){sin(point*angle), cos(point*angle)};
            fairyVertices[vtx].position *= FairySize;
        }

        _fairy = [_device newBufferWithBytes:fairyVertices length:sizeof(fairyVertices) options:0];
    }
}

/// Initialize light positions and colors
- (void)populateLights
{
    AAPLPointLight *light_data = (AAPLPointLight*)_lightsData.contents;
    vector_float4 *light_position = (vector_float4*)_lightWorldPositions[0].contents;

    srand(0x134e5348);

    for(NSUInteger lightId = 0; lightId < AAPLNumLights; lightId++)
    {
        float distance = 0;
        float height = 0;
        float angle = 0;
        if(lightId < AAPLNumLights/4) {
            distance = random_float(140,260);
            height = random_float(140,150);
            angle = random_float(0, M_PI*2);
        } else if(lightId < (AAPLNumLights*3)/8) {
            distance = random_float(350,362);
            height = random_float(140,400);
            angle = random_float(0, M_PI*2);
        } else if(lightId < (AAPLNumLights*15)/16) {
            distance = random_float(400,480);
            height = random_float(68,80);
            angle = random_float(0, M_PI*2);
        }else {
            distance = random_float(40,40);
            height = random_float(220,350);
            angle = random_float(0, M_PI*2);

        }

        light_data->lightRadius = random_float(25,35);
        *light_position = (vector_float4){ distance*sinf(angle),height,distance*cosf(angle),light_data->lightRadius};
        light_data->lightSpeed = random_float(0.003,0.015);
        int colorId = rand()%3;
        if( colorId == 0) {
            light_data->lightColor = (vector_float3){random_float(2,3),random_float(0,2),random_float(0,2)};
        } else if ( colorId == 1) {
            light_data->lightColor = (vector_float3){random_float(0,2),random_float(2,3),random_float(0,2)};
        } else {
            light_data->lightColor = (vector_float3){random_float(0,2),random_float(0,2),random_float(2,3)};
        }

        light_data++;
        light_position++;
    }

    memcpy(_lightWorldPositions[1].contents, _lightWorldPositions[0].contents, AAPLNumLights * sizeof(vector_float3));
    memcpy(_lightWorldPositions[2].contents, _lightWorldPositions[0].contents, AAPLNumLights * sizeof(vector_float3));
}

/// Update light positions
- (void)updateLights
{
    int previousFramesBufferIndex = (_currentBufferIndex+AAPLMaxBuffersInFlight-1)%AAPLMaxBuffersInFlight;

    AAPLPointLight *lightData = (AAPLPointLight*)((char*)_lightsData.contents);

    const AAPLUniforms * uniforms = (AAPLUniforms*)_uniformBuffers[_currentBufferIndex].contents;
    const matrix_float4x4 viewMatrix = uniforms->viewMatrix;

    vector_float4 *previousWorldSpacePositions =
        (vector_float4*) _lightWorldPositions[previousFramesBufferIndex].contents;

    vector_float4 *currentWorldSpaceLightPositions =
        (vector_float4*) _lightWorldPositions[_currentBufferIndex].contents;

    vector_float4 *currentEyeSpaceLightPositions =
        (vector_float4*) _lightEyePositions[_currentBufferIndex].contents;

    for(int i = 0; i < AAPLNumLights; i++)
    {
        matrix_float4x4 rotation = matrix4x4_rotation(lightData[i].lightSpeed, 0, 1, 0);

        vector_float4 previousWorldSpacePosition = {
            previousWorldSpacePositions[i].x,
            previousWorldSpacePositions[i].y,
            previousWorldSpacePositions[i].z,
            1
        };

        vector_float4 currentWorldSpacePosition = matrix_multiply(rotation, previousWorldSpacePosition);

        vector_float4 currentEyeSpacePosition = matrix_multiply(viewMatrix, currentWorldSpacePosition);

        currentWorldSpacePosition.w = lightData[i].lightRadius;
        currentEyeSpacePosition.w = lightData[i].lightRadius;

        currentWorldSpaceLightPositions[i] = currentWorldSpacePosition;
        currentEyeSpaceLightPositions[i] = currentEyeSpacePosition;
    }
}

/// Update application state for the current frame
- (void)updateGameState
{
    _currentBufferIndex = (_currentBufferIndex + 1) % AAPLMaxBuffersInFlight;

    AAPLUniforms * uniforms = (AAPLUniforms*)_uniformBuffers[_currentBufferIndex].contents;

    // Update ambient light color
	vector_float3 ambientLightColor = {0.05, 0.05, 0.05};
    uniforms->ambientLightColor = ambientLightColor;

    // Update directional light direciton in world's space
	vector_float3 directionalLightDirection = {1.0, -1.0, 1.0};
    uniforms->directionalLightDirection = directionalLightDirection;

    // Update directional light color
    vector_float3 directionalLightColor = {.4, .4, .4};
    uniforms->directionalLightColor = directionalLightColor;;

    // Set projection matrix and calculate inverted projection matrix
    uniforms->projectionMatrix = _projectionMatrix;
    uniforms->projectionMatrixInv = matrix_invert(_projectionMatrix);
    uniforms->depthUnproject = vector2(_farPlane / (_farPlane - _nearPlane), (-_farPlane * _nearPlane) / (_farPlane - _nearPlane));

    // Set screen dimmensions
    uniforms->framebufferWidth = (uint)_depthData.width;
    uniforms->framebufferHeight = (uint)_depthData.height;

    float fovScale = tanf(0.5 * _fov) * 2.0;
    float aspectRatio = (float)uniforms->framebufferWidth / uniforms->framebufferHeight;
    uniforms->screenToViewSpace = vector3(fovScale / uniforms->framebufferHeight, -fovScale * 0.5f * aspectRatio, -fovScale * 0.5f);

    // Calculate new view matrix and inverted view matrix
    uniforms->viewMatrix = matrix_multiply(matrix4x4_translation(0.0, 0, 1000.5),
                                           matrix_multiply(matrix4x4_rotation(-0.5, (vector_float3){1,0,0}),
                                                           matrix4x4_rotation(_rotation, (vector_float3){0,1,0} )));
    uniforms->viewMatrixInv = matrix_invert(uniforms->viewMatrix);

    vector_float3 rotationAxis = {0, 1, 0};
    matrix_float4x4 modelMatrix = matrix4x4_rotation(0, rotationAxis);
    matrix_float4x4 translation = matrix4x4_translation(0.0, 0, 0);
    modelMatrix = matrix_multiply(modelMatrix, translation);

    uniforms->modelViewMatrix = matrix_multiply(uniforms->viewMatrix, modelMatrix);
    uniforms->modelMatrix = modelMatrix;

    uniforms->normalMatrix = matrix3x3_upper_left(uniforms->modelViewMatrix);
    uniforms->normalMatrix = matrix_invert(matrix_transpose(uniforms->normalMatrix));

    _rotation += 0.002f;

    [self updateLights];
}

/// Called whenever view changes orientation or layout is changed
- (void) mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // When reshape is called, update the aspect ratio and projection matrix since the view
    //   orientation or size has changed
	float aspect = size.width / (float)size.height;
    _fov = 65.0f * (M_PI / 180.0f);
    _nearPlane = 1.0f;
    _farPlane = 1500.0f;
    _projectionMatrix = matrix_perspective_left_hand(_fov, aspect, _nearPlane, _farPlane);

    MTLTextureDescriptor *depthBufferDesc =
    [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                       width:size.width
                                                      height:size.height
                                                   mipmapped:NO];

    if(view.sampleCount > 1) {
        depthBufferDesc.textureType = MTLTextureType2DMultisample;
    } else {
        depthBufferDesc.textureType = MTLTextureType2D;
    }

    depthBufferDesc.sampleCount = view.sampleCount;
    depthBufferDesc.usage |= MTLTextureUsageRenderTarget;
    depthBufferDesc.storageMode = MTLStorageModeMemoryless;

    depthBufferDesc.pixelFormat = MTLPixelFormatR32Float;
    _depthData = [_device newTextureWithDescriptor:depthBufferDesc];
}

/// Draw our AAPLMesh objects with the given renderEncoder
- (void)drawMeshes:(id<MTLRenderCommandEncoder>)renderEncoder
{
    for (__unsafe_unretained AAPLMesh *mesh in _meshes)
    {
        __unsafe_unretained MTKMesh *metalKitMesh = mesh.metalKitMesh;

        // Set mesh's vertex buffers
        for (NSUInteger bufferIndex = 0; bufferIndex < metalKitMesh.vertexBuffers.count; bufferIndex++)
        {
            __unsafe_unretained MTKMeshBuffer *vertexBuffer = metalKitMesh.vertexBuffers[bufferIndex];
            if((NSNull*)vertexBuffer != [NSNull null])
            {
                [renderEncoder setVertexBuffer:vertexBuffer.buffer
                                        offset:vertexBuffer.offset
                                       atIndex:bufferIndex];
            }
        }

        // Draw each submesh of our mesh
        for(AAPLSubmesh *submesh in mesh.submeshes)
        {
            // Set any textures read/sampled from our render pipeline
            [renderEncoder setFragmentTexture:submesh.textures[AAPLTextureIndexBaseColor]
                                      atIndex:AAPLTextureIndexBaseColor];

            [renderEncoder setFragmentTexture:submesh.textures[AAPLTextureIndexNormal]
                                      atIndex:AAPLTextureIndexNormal];

            [renderEncoder setFragmentTexture:submesh.textures[AAPLTextureIndexSpecular]
                                      atIndex:AAPLTextureIndexSpecular];

            MTKSubmesh *metalKitSubmesh = submesh.metalKitSubmmesh;

            [renderEncoder drawIndexedPrimitives:metalKitSubmesh.primitiveType
                                      indexCount:metalKitSubmesh.indexCount
                                       indexType:metalKitSubmesh.indexType
                                     indexBuffer:metalKitSubmesh.indexBuffer.buffer
                               indexBufferOffset:metalKitSubmesh.indexBuffer.offset];
        }
    }
}

// Called whenever the view needs to render
- (void) drawInMTKView:(nonnull MTKView *)view
{
    // Wait to ensure only AAPLMaxBuffersInFlight are getting proccessed by any stage in the Metal
    //   pipeline (App, Metal, Drivers, GPU, etc)
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    // Create a new command buffer for each renderpass to the current drawable
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    // Add completion hander which signal _inFlightSemaphore when Metal and the GPU has fully
    //   finished proccssing the commands we're encoding this frame.  This indicates when the
    //   dynamic buffers, that we're writing to this frame, will no longer be needed by Metal
    //   and the GPU.
    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
    {
        dispatch_semaphore_signal(block_sema);
    }];

    [self updateGameState];

    // Obtain a renderPassDescriptor generated from the view's drawable textures
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    renderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].texture = _depthData;
    renderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].storeAction = MTLStoreActionDontCare;

    renderPassDescriptor.tileWidth = AAPLTileWidth;
    renderPassDescriptor.tileHeight = AAPLTileHeight;
    renderPassDescriptor.threadgroupMemoryLength = AAPLThreadgroupBufferSize + AAPLTileDataSize; // list of
    // If we've gotten a renderPassDescriptor we can render to the drawable, otherwise we'll skip
    //   any rendering this frame because we have no drawable to draw to

    if(renderPassDescriptor != nil) {
        // Create a render command encoder so we can render into something
        id <MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

        [renderEncoder setCullMode:MTLCullModeBack];

        // Render Scene to Depth buffer only (so we can determine min max depth bounds for culling)
        [renderEncoder pushDebugGroup:@"Depth Pre-Pass"];
        [renderEncoder setRenderPipelineState:_depthPrePassPipelineState];
        [renderEncoder setDepthStencilState:_defaultDepthState];
        [renderEncoder setVertexBuffer:_uniformBuffers[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexUniforms];
        [self drawMeshes:renderEncoder];
        [renderEncoder popDebugGroup];

        // Perform Tile Culling (to minimize the number of lights rendered per tile)
        [renderEncoder pushDebugGroup:@"Prepare Light Lists"];
        [renderEncoder setRenderPipelineState:_lightCullingPipelineState];
        [renderEncoder setThreadgroupMemoryLength:AAPLThreadgroupBufferSize offset:0 atIndex:AAPLThreadgroupBufferIndexLightList];
        [renderEncoder setThreadgroupMemoryLength:AAPLTileDataSize offset:AAPLThreadgroupBufferSize atIndex:AAPLThreadgroupBufferIndexTileData];
        [renderEncoder setTileBuffer:_uniformBuffers[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexUniforms];
        [renderEncoder setTileBuffer:_lightEyePositions[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexLightsPosition];
        [renderEncoder dispatchThreadsPerTile:MTLSizeMake(AAPLTileWidth,AAPLTileHeight,1)];
        [renderEncoder popDebugGroup];

        // Render Objects with Lighting
        [renderEncoder pushDebugGroup:@"Render Forward Lighting"];
        [renderEncoder setRenderPipelineState:_forwardLightingPipelineState];
        [renderEncoder setDepthStencilState:_relaxedDepthState];
        [renderEncoder setVertexBuffer:_uniformBuffers[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexUniforms];
        [renderEncoder setFragmentBuffer:_uniformBuffers[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexUniforms];
        [renderEncoder setFragmentBuffer:_lightsData offset:0 atIndex:AAPLBufferIndexLightsData];
        [renderEncoder setFragmentBuffer:_lightWorldPositions[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexLightsPosition];
        [self drawMeshes:renderEncoder];
        [renderEncoder popDebugGroup];

        // Draw fairies
        [renderEncoder pushDebugGroup:@"Draw Fairies"];
        [renderEncoder setRenderPipelineState:_fairyPipelineState];
        [renderEncoder setDepthStencilState:_defaultDepthState];
        [renderEncoder setVertexBuffer:_uniformBuffers[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexUniforms];
        [renderEncoder setVertexBuffer:_fairy offset:0 atIndex:AAPLBufferIndexMeshPositions];
        [renderEncoder setVertexBuffer:_lightsData offset:0 atIndex:AAPLBufferIndexLightsData];
        [renderEncoder setVertexBuffer:_lightWorldPositions[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexLightsPosition];
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:AAPLNumFairyVertices instanceCount:AAPLNumLights];
        [renderEncoder popDebugGroup];

        // We're done encoding commands
        [renderEncoder endEncoding];

    }

    // Schedule a present once the framebuffer is complete using the current drawable
    [commandBuffer presentDrawable:view.currentDrawable];

    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
}

@end

