//
//  Renderer.swift
//  MetalBilinearFiltering Shared
//
//  Created by JazzG on 8/14/20.
//  Copyright © 2020 JazzG. All rights reserved.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

enum RendererError: Error {
    case badVertexDescriptor
}

class Renderer: NSObject, MTKViewDelegate {
    
    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState
    var depthState: MTLDepthStencilState
    var sourceTexture: MTLTexture
    var targetTexture: MTLTexture

    // vertex
    let fullScreenQuad: [Float] = [-1,  1.0, 0, 0,
                                   -1, -1.0, 0, 1,
                                    1,  1.0, 1, 0,
                                   -1, -1.0, 0, 1,
                                    1, -1.0, 1, 1,
                                    1,  1.0, 1, 0]
    var vertexBuffer : MTLBuffer

/*
               /\ (y)
        tl      |       tr
                |
                |
      --------------------->x
                |
                |
        b l     |       br


*/




    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        guard let queue = self.device.makeCommandQueue() else { return nil }
        self.commandQueue = queue
        
        metalKitView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        metalKitView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        metalKitView.sampleCount = 1
        
        let mtlVertexDescriptor = Renderer.buildMetalVertexDescriptor()
        
        do {
            pipelineState = try Renderer.buildRenderPipelineWithDevice(device: device,
                                                                       metalKitView: metalKitView,
                                                                       mtlVertexDescriptor: mtlVertexDescriptor)
        } catch {
            print("Unable to compile render pipeline state.  Error info: \(error)")
            return nil
        }
        
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = MTLCompareFunction.always
        depthStateDesciptor.isDepthWriteEnabled = true
        guard let state = device.makeDepthStencilState(descriptor:depthStateDesciptor) else { return nil }
        depthState = state

        // create source/target
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: 5, height: 1, mipmapped: false)
        let sourceData : [Float] = [1, 2, 3, 4, 5]
        sourceTexture = self.device.makeTexture(descriptor: descriptor)!
        sourceTexture.replace(region: MTLRegionMake2D(0, 0, 5, 1),
                              mipmapLevel: 0,
                              withBytes: sourceData,
                              bytesPerRow: MemoryLayout.size(ofValue: sourceData[0]) * 5)
        //target
        descriptor.pixelFormat = .rgba32Float
//        descriptor.width = 10
//        descriptor.height = 10
        descriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        targetTexture = self.device.makeTexture(descriptor: descriptor)!

        // vb
        let dataSize = fullScreenQuad.count * MemoryLayout.size(ofValue: fullScreenQuad[0])
        vertexBuffer = self.device.makeBuffer(bytes: fullScreenQuad, length: dataSize, options: [])!

        super.init()
    }
    
    class func buildMetalVertexDescriptor() -> MTLVertexDescriptor {
        // Creete a Metal vertex descriptor specifying how vertices will by laid out for input into our render
        //   pipeline and how we'll layout our Model IO vertices
        
        let mtlVertexDescriptor = MTLVertexDescriptor()
        
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].format = MTLVertexFormat.float2
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].bufferIndex = 0
        
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].format = MTLVertexFormat.float2
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].offset = 2 * MemoryLayout<Float>.stride
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].bufferIndex = 0
        
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stride = 16
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        return mtlVertexDescriptor
    }
    
    class func buildRenderPipelineWithDevice(device: MTLDevice,
                                             metalKitView: MTKView,
                                             mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object
        
        let library = device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.sampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = .rgba32Float
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func draw(in view: MTKView) {
        /// Per frame updates hare
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
            ///   holding onto the drawable and blocking the display pipeline any longer than necessary
            let renderPassDescriptor = view.currentRenderPassDescriptor
            renderPassDescriptor!.colorAttachments[0].texture = targetTexture
            renderPassDescriptor!.colorAttachments[0].loadAction = .clear
            renderPassDescriptor!.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
            renderPassDescriptor!.colorAttachments[0].storeAction = .store

            if let renderPassDescriptor = renderPassDescriptor, let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                
                /// Final pass rendering code here
                renderEncoder.label = "Primary Render Encoder"
                
                renderEncoder.pushDebugGroup("Draw Box")
                
                renderEncoder.setCullMode(.back)
                
                renderEncoder.setFrontFacing(.counterClockwise)
                
                renderEncoder.setRenderPipelineState(pipelineState)
                
                renderEncoder.setDepthStencilState(depthState)

                renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

                renderEncoder.setFragmentTexture(sourceTexture, index: 0)   // TextureIndexSource

                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

                renderEncoder.popDebugGroup()
                
                renderEncoder.endEncoding()
                
                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                }
            }
            
            commandBuffer.commit()
        }

/*
        var cpuMem = UnsafeMutableRawPointer.allocate(byteCount: 4*256, alignment: 0)
        targetTexture.getBytes(cpuMem, bytesPerRow: 4*256, from: MTLRegionMake2D(0, 0, 5, 1), mipmapLevel: 0)

        printx(address: cpuMem, as: Float.self)

        cpuMem.deallocate()
*/
    }

/*
    func printx<T>(address p: UnsafeMutableRawPointer, as type: T.Type) {
        let value = p.load(as: type)
        print(value)

        let p2 = p.advanced(by: 4)
        let value2 = p2.load(as: type)
        print(value2)

        let p3 = p2.advanced(by: 4)
        let value3 = p3.load(as: type)
        print(value3)

    }
*/

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here

    }
}

