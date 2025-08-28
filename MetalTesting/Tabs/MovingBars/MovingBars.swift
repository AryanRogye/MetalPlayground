//
//  MovingBars.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

import SwiftUI
import Metal
import MetalKit

struct MovingBarsView: View {
    var body: some View {
        VStack {
            BarView()
            Text("Example View")
        }
    }
}

struct BarView: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        let mtkView = MTKView()
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("no Device Found")
            fatalError()
        }
        mtkView.device = device
        mtkView.delegate = context.coordinator
        return mtkView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    func makeCoordinator() -> BarViewCoordinator {
        BarViewCoordinator()
    }
    
    class BarViewCoordinator: NSObject, MTKViewDelegate {
        
        private var device: MTLDevice!
        private var queue: MTLCommandQueue!
        private var pso: MTLRenderPipelineState!
        
        private var vertexBuffer : MTLBuffer!
        private var colorBuffer  : MTLBuffer!
        
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
            desc.vertexFunction   = lib.makeFunction(name: "vertexBarShader")
            desc.fragmentFunction = lib.makeFunction(name: "fragmentBarShader")
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
        }
        func draw(in view: MTKView) {
            guard let rpd = view.currentRenderPassDescriptor,
                  let drw = view.currentDrawable else { return }
            
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
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            
            enc.endEncoding()
            cmd.present(drw)
            cmd.commit()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    }
}

#Preview {
    MovingBarsView()
}
