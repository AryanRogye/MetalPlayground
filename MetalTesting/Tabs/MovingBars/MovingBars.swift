//
//  MovingBars.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

import SwiftUI
import Metal
import MetalKit

#if os(iOS)
struct MovingBarsView: View {
    
    @StateObject private var barCoordinator: BarCoordinator = BarCoordinator()
    
    var body: some View {
        VStack {
            Spacer()
            /// When they internally change the heights they should be aligned to the
            /// bottom so they look like their going into it
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .bottom) {
                    ForEach(0..<barCoordinator.barNumber, id: \.self) { index in
                        VStack {
                            BarView(
                                toggleMove: $barCoordinator.toggleMove,
                                barCoordinator: barCoordinator
                            )
                            .frame(width: 50, height: 80)
                            Text("\(index)")
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                    }
                }
                .padding(.bottom)
            }
            .frame(alignment: .center)
            .defaultScrollAnchor(.center)

            Spacer()
            HStack {
                decrementButton
                Spacer()
                playButton
                Spacer()
                incrementButton
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var incrementButton: some View {
        Button(action: {
            barCoordinator.incrementBarNumber()
        }) {
            Image(systemName: "plus")
                .resizable()
                .frame(width: 50, height: 50)
        }
    }
    
    private var decrementButton: some View {
        Button(action: {
            barCoordinator.decrementBarNumber()
        }) {
            Image(systemName: "minus")
                .resizable()
                .frame(width: 50, height: 10)
        }
    }
    
    private var playButton: some View {
        Button(action: {
            withAnimation(.snappy) {
                barCoordinator.toggleMove.toggle()
            }
        }) {
            Image(systemName: barCoordinator.toggleMove ? "pause.fill" : "play.fill")
                .resizable()
                .frame(width: 50, height: 50)
        }
    }
}


class BarCoordinator: ObservableObject {
    @Published var toggleMove: Bool = false
    @Published var barNumber : Int = 3
    
    private let minBars = 1
    private let maxBars = 100
    
    public func decrementBarNumber() {
        barNumber = max(barNumber - 1, minBars)
    }
    
    public func incrementBarNumber() {
        barNumber = min(barNumber + 1, maxBars)
    }
}

struct BarView: UIViewRepresentable {
    
    @Binding var toggleMove: Bool
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
        private var barUniformBuffer : MTLBuffer!
        
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
            barUniformBuffer = device.makeBuffer(
                length: MemoryLayout<BarUniforms>.stride,
                options: []
            )
        }
        
        func draw(in view: MTKView) {
            guard let rpd = view.currentRenderPassDescriptor,
                  let drw = view.currentDrawable else { return }
            
            
            /// We Edit Contents if we have set barCoordinator
            if let barCoordinator = barCoordinator {
                let barUniformBufferInfo = barUniformBuffer.contents().bindMemory(to: BarUniforms.self, capacity: 1)
                barUniformBufferInfo.pointee = BarUniforms(
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
                barUniformBuffer,
                offset: 0,
                index: 2
            )
            
            cmd.addCompletedHandler { cb in
                DispatchQueue.main.async {
                    MetalRootCoordinator.shared.handleCommandBufferExecutionTime(cb, from: "Moving Bars")
                }
            }

            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            
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

#endif
