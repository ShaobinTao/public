//
//  ViewController.swift
//  MTKViewTest
//
//  Created by test on 3/5/20.
//  Copyright © 2020 test. All rights reserved.
//

import UIKit
import Metal
import MetalKit

class ViewController: UIViewController, MTKViewDelegate {
    @IBOutlet weak var mtkView: MTKView!
    
    var device : MTLDevice!
    var commandQueue : MTLCommandQueue!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()

        mtkView.delegate = self
        
        // render
        commandQueue = device.makeCommandQueue()!
    }

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


}

