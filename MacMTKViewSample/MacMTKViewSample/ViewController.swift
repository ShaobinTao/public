//
//  ViewController.swift
//  MacMTKViewSample
//
//  Created by test on 1/29/20.
//  Copyright © 2020 test. All rights reserved.
//

import Cocoa
import Metal
import MetalKit

class ViewController: NSViewController, MTKViewDelegate {
    var mtkView : MTKView!
    var device : MTLDevice!
    var commandQueue : MTLCommandQueue!
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("draw")
    }
    
    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        
        encoder?.endEncoding()
        
        let drawable = view.currentDrawable!
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        device = MTLCreateSystemDefaultDevice()
        
        mtkView = (self.view as! MTKView)
        mtkView.enableSetNeedsDisplay = true
        mtkView.device = device
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)

        mtkView.delegate = self
        
        // render
        commandQueue = device.makeCommandQueue()!
        
    }


}

