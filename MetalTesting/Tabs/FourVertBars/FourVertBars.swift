//
//  FourVertBars.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

import SwiftUI
import Metal
import MetalKit

#if os(iOS)

struct FourVertBarsView: View {
    
    @StateObject private var coordinator = FourVertBarsCoordinator()
    
    var body: some View {
        VStack(spacing: 0) {
            FourVertView(
                fourVertBarsCoordinator: coordinator
            )
            bottomBar
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var bottomBar: some View {
        VStack {
            HStack {
                decreaseBarsButton
                Spacer()
                Text("Bars: \(coordinator.barNumber)")
                Spacer()
                increaseBarsButton
            }
            HStack {
                decreaseGapButton
                Spacer()
                Text("Gaps: \(coordinator.gap)")
                Spacer()
                increaseGapButton
            }
            HStack {
                Spacer()
                pauseBarsPlayButton
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var decreaseGapButton: some View {
        minusButton {
            coordinator.decrementGap()
        }
    }
    private var increaseGapButton: some View {
        addButton {
            coordinator.incrementGap()
        }
    }
    
    private var pauseBarsPlayButton: some View {
        Button(action: {
            coordinator.toggleAnimation.toggle()
        }) {
            Image(systemName: coordinator.toggleAnimation
                  ? "pause"
                  : "play"
            )
            .resizable()
            .frame(width: 32, height: 32)
        }
    }
    
    private var decreaseBarsButton: some View {
        minusButton {
            coordinator.decrementBarNumber()
        }
    }
    private var increaseBarsButton: some View {
        addButton {
            coordinator.incrementBarNumber()
        }
    }
    
    @ViewBuilder
    private func minusButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "minus")
                .resizable()
                .frame(width: 32, height: 5)
        }
    }
    
    @ViewBuilder
    private func addButton(action: @escaping () -> Void) -> some View {
        Button(action: action)  {
            Image(systemName: "plus")
                .resizable()
                .frame(width: 32, height: 32)
        }
    }
}

class FourVertBarsCoordinator: ObservableObject {
    @Published var toggleAnimation: Bool = false
    
    @Published var barNumber: Int = 3
    @Published var gap: CGFloat = 0.1
    
    private let minBars = 1
    private let maxBars = 100
    
    private let minGap: CGFloat = 0
    private let maxGap: CGFloat = 0.9
    
    public func decrementBarNumber() {
        barNumber = max(barNumber - 1, minBars)
    }
    
    public func incrementBarNumber() {
        barNumber = min(barNumber + 1, maxBars)
    }
    
    public func decrementGap() {
        gap = max(gap - 0.1, minGap)
    }
    public func incrementGap() {
        gap = min(gap + 0.1, maxGap)
    }
}

struct FourVertView: UIViewRepresentable {
    
    @ObservedObject var fourVertBarsCoordinator : FourVertBarsCoordinator
    
    func makeCoordinator() -> FourVertMetalCoordinator {
        FourVertMetalCoordinator()
    }
    
    func makeUIView(context: Context) -> some UIView {
        let mtkView = MTKView()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("no Device Found")
            fatalError()
        }
        mtkView.device = device
        context.coordinator.fourVertBarsCoordinator = fourVertBarsCoordinator
        mtkView.delegate = context.coordinator
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 120
        mtkView.framebufferOnly = true             // if you don’t sample attachments later
        mtkView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        return mtkView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    class FourVertMetalCoordinator: NSObject, MTKViewDelegate {
        
        var fourVertBarsCoordinator: FourVertBarsCoordinator?
        private var device: MTLDevice!
        private var queue: MTLCommandQueue!
        private var pso: MTLRenderPipelineState!
        
        private var vertexBuffer: MTLBuffer!
        private var colorBuffer : MTLBuffer!
        private var barUniformBuffer : MTLBuffer!
        
        private var verts: [Vertex] = [
            .init(pos: [-1, -1]),
            .init(pos: [-1, 1]),
            .init(pos: [1, -1]),
            .init(pos: [1, 1])
        ]
        private var colors: [SIMD3<Float>] = [
            [1, 0, 0], // red
            [0, 1, 0], // green
            [0, 0, 1],  // blue
            [1, 0, 0], // red
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
            desc.vertexFunction   = lib.makeFunction(name: "fourVertBarsVertex")
            desc.fragmentFunction = lib.makeFunction(name: "fourVertBarsFragment")
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
                length: MemoryLayout<FourBarUniforms>.stride,
                options: []
            )
        }

        func draw(in view: MTKView) {
            guard let rpd = view.currentRenderPassDescriptor,
                  let drw = view.currentDrawable else { return }
            
            let cmd = queue.makeCommandBuffer()!
            let enc = cmd.makeRenderCommandEncoder(descriptor: rpd)!
            
            if let fourVertBarsCoordinator = fourVertBarsCoordinator {
                let u = barUniformBuffer.contents().bindMemory(to: FourBarUniforms.self, capacity: 1)
                u.pointee = FourBarUniforms(
                    number: Float(fourVertBarsCoordinator.barNumber),
                    shouldAnimate: fourVertBarsCoordinator.toggleAnimation ? 1.0 : 0.0,
                    time: Float(CACurrentMediaTime()),
                    gap: Float(fourVertBarsCoordinator.gap)
                )
            }

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
            
            let count = max(1, fourVertBarsCoordinator?.barNumber ?? 1)
            NSLog("Using InstanceCount: %d", count)
            enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: count)
            
            cmd.addCompletedHandler { cb in
                MetalRootCoordinator.shared.handleCommandBufferExecutionTime(cb, from: "Four Vert Bars")
            }
            
            enc.endEncoding()
            cmd.present(drw)
            cmd.commit()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    }
}

#Preview {
    FourVertBarsView()
}


#endif
