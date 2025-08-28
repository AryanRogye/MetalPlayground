//
//  OptimizedMovingBarsMetal.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

import Metal
import MetalKit
import SwiftUI

struct OptimizedBarView: UIViewRepresentable {
    
    @ObservedObject var barCoordinator: BarCoordinator
    
    func makeUIView(context: Context) -> some UIView {
        let mtkView = MTKView()
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("no Device Found")
            fatalError()
        }
        mtkView.device = device
        mtkView.delegate = context.coordinator
        mtkView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        context.coordinator.barCoordinator = barCoordinator
        return mtkView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    func makeCoordinator() -> BarViewCoordinator {
        BarViewCoordinator()
    }
    
    class BarViewCoordinator: NSObject, MTKViewDelegate {
        
        var barCoordinator: BarCoordinator? = nil
        private var device: MTLDevice!
        private var queue: MTLCommandQueue!
        private var pso: MTLRenderPipelineState!
        
        private var vertexBuffer : MTLBuffer!
        private var colorBuffer  : MTLBuffer!
        private var optimizedBarBuffer : MTLBuffer!
        
        var colors: [SIMD3<Float>] = [
            [1, 0, 0], // red
            [0, 1, 0], // green
            [0, 0, 1],  // blue
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
            .init(pos: [1, 1]),
            
            /// Bottom Left
            .init(pos: [-1, -1]),
            /// Bottom Right
            .init(pos: [1, -1]),
            /// Top Right
            .init(pos: [1, 1]),
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
            desc.vertexFunction   = lib.makeFunction(name: "vertexOptimizedBarShader")
            desc.fragmentFunction = lib.makeFunction(name: "fragmentOptimizedBarShader")
            desc.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            pso = try! device.makeRenderPipelineState(descriptor: desc)
            
            vertexBuffer = device.makeBuffer(
                bytes: verts,
                length: MemoryLayout<Vertex>.stride * verts.count
            )
            colorBuffer = device.makeBuffer(
                bytes: colors,
                length: MemoryLayout<SIMD3<Float>>.stride * colors.count,
                options: []
            )
            optimizedBarBuffer = device.makeBuffer(
                length: MemoryLayout<OptimizedBarUniforms>.stride,
                options: []
            )
        }
        
        func draw(in view: MTKView) {
            guard let rpd = view.currentRenderPassDescriptor,
                  let drw = view.currentDrawable else { return }
            
            
            /// We Edit Contents if we have set barCoordinator
            if let barCoordinator = barCoordinator {
                let barUniformBufferInfo = optimizedBarBuffer.contents().bindMemory(to: OptimizedBarUniforms.self, capacity: 1)
                barUniformBufferInfo.pointee = OptimizedBarUniforms(
                    number: Float(barCoordinator.barNumber),
                    time: barCoordinator.toggleMove ? Float(CACurrentMediaTime()) : Float(0.0),
                    shouldAnimate: barCoordinator.toggleMove ? 1.0 : 0.0
                )
            }
            
            
            let cmd = queue.makeCommandBuffer()!
            let enc = cmd.makeRenderCommandEncoder(descriptor: rpd)!
            
            enc.setRenderPipelineState(pso)
            enc.setVertexBuffer(
                vertexBuffer,
                offset: 0,
                index: 0
            )
            enc.setVertexBuffer(
                colorBuffer,
                offset: 0,
                index: 1
            )
            enc.setVertexBuffer(
                optimizedBarBuffer,
                offset: 0,
                index: 2
            )
            
            if let barCoordinator = barCoordinator {
                enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 6, instanceCount: barCoordinator.barNumber)
            } else {
                enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 6)
            }
            
            cmd.addCompletedHandler { cb in
                MetalRootCoordinator.shared.handleCommandBufferExecutionTime(cb, from: "Optimized Moving Bars")
            }
            
            enc.endEncoding()
            cmd.present(drw)
            cmd.commit()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    }
}
