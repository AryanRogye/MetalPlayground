//
//  TriangleTestMetal.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

import Metal
import MetalKit
import SwiftUI
import Combine

#if os(iOS)

final class TriangleTestMetalCoordinator: ObservableObject {
    fileprivate let renderer = TriangleTestMetal.RendererCoordinator()
    private weak var view: MTKView?
    
    func attach(_ view: MTKView) {
        self.view = view
    }
    
    func resume() {
        view?.isPaused = false
        view?.delegate = renderer
    }
    
    func pause() {
        view?.isPaused = true
        view?.delegate = nil
    }
}


struct TriangleTestMetal: UIViewRepresentable {
    
    @ObservedObject var TriangleTestMetalCoordinator: TriangleTestMetalCoordinator
    
    // Add helpers you can call from SwiftUI:
    func pause(_ view: MTKView, _ coordinator: RendererCoordinator) {
        view.isPaused = true
        view.delegate = nil
    }
    func resume(_ view: MTKView, _ coordinator: RendererCoordinator) {
        view.isPaused = false
        view.delegate = coordinator
    }
    
    func makeCoordinator() -> RendererCoordinator {
        RendererCoordinator()
    }
    
    func makeUIView(context: Context) -> some UIView {
        let mtkView = MTKView()
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Error: Metal is not supported on this device.")
            return MTKView()
        }
        mtkView.device = device
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 120
        mtkView.isUserInteractionEnabled = true
        /// Setting White Background
        mtkView.clearColor = MTLClearColor(
            red: 1.0,
            green: 1.0,
            blue: 1.0,
            alpha: 1.0
        )
        
        return mtkView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    class RendererCoordinator: NSObject ,MTKViewDelegate {
        
        private var device: MTLDevice!
        private var queue: MTLCommandQueue!
        private var pso: MTLRenderPipelineState!
        
        private var vbuf: MTLBuffer!
        private var color: MTLBuffer!
        private var time: MTLBuffer!
        private var triangleInfoBuffer: MTLBuffer!
        
        private var start = CACurrentMediaTime()
        
        
        var colors: [SIMD3<Float>] = [
            [1, 0, 0], // red
            [0, 1, 0], // green
            [0, 0, 1]  // blue
        ]
        // 2 triangles (6 verts): NDC xy, UV zw
        let verts: [Vertex] = [
            /// Bottom Left
            .init(pos: [-1, -1]),
            /// Top Left
            .init(pos: [-1, 1]),
            /// Top Right
            .init(pos: [1, 1])
        ]
        
        override init() {
            super.init()
            setupMetal()
        }
        
        private func setupMetal() {
            device = MTLCreateSystemDefaultDevice()!
            queue  = device.makeCommandQueue()!
            let lib = device.makeDefaultLibrary()!
            
            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction   = lib.makeFunction(name: "vertexShader")
            desc.fragmentFunction = lib.makeFunction(name: "fragmentShader")
            desc.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            pso = try! device.makeRenderPipelineState(descriptor: desc)
            
            vbuf = device.makeBuffer(
                /// Byes, copies the contents of that array into GPU memory.
                bytes: verts,   /// Swift Array
                /// tells Metal how many bytes to copy.
                length: MemoryLayout<Vertex>.stride * verts.count
            )!
            color = device.makeBuffer(
                bytes: colors,
                length: MemoryLayout<SIMD3<Float>>.stride * colors.count,
                options: []
            )
            triangleInfoBuffer = device.makeBuffer(
                length: MemoryLayout<TriangleInfo>.stride,
                options: []
            )
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            guard let rpd = view.currentRenderPassDescriptor,
                  let drw = view.currentDrawable else { return }
            
            let tInfo = triangleInfoBuffer.contents().bindMemory(to: TriangleInfo.self, capacity: 1)
            tInfo.pointee = TriangleInfo(
                min: MetalBackgroundParameters.shared.minimum,
                max: MetalBackgroundParameters.shared.maximum,
                time: Float(CACurrentMediaTime()),
                speed: MetalBackgroundParameters.shared.speed
            )
            
            let cmd = queue.makeCommandBuffer()!
            let enc = cmd.makeRenderCommandEncoder(descriptor: rpd)!
            
            enc.setRenderPipelineState(pso)
            
            /// Set Vertex Buffer for Shape
            enc.setVertexBuffer(
                vbuf,
                offset: 0,
                index: 0
            )
            /// Set Vertex Buffer for Color
            enc.setVertexBuffer(
                color,
                offset: 0,
                index: 1
            )
            enc.setVertexBuffer(
                triangleInfoBuffer,
                offset: 0,
                index: 2
            )
            /// Set Vertex Bytes For Time
            ///
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            
            cmd.addCompletedHandler { cb in
                MetalRootCoordinator.shared.handleCommandBufferExecutionTime(cb, from: "Triangle Test")
            }

            enc.endEncoding()
            cmd.present(drw)
            cmd.commit()
        }
    }
}

#endif
