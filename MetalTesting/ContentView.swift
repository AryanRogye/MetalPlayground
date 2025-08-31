//
//  ContentView.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/26/25.
//

import SwiftUI
import Combine
import Metal
import MetalKit

enum Tabs: String, CaseIterable {
#if os(iOS)
    case triangle_test = "Triangle Test"
    case moving_bars   = "Moving Bars"
    case moving_bars_optimized = "Moving Bars Optimized"
    case moving_bars_4_vertices = "Moving Bars 4 Vertices"
#endif
    case dominant_color_in_image = "Dominant Color In Image"
    
    @ViewBuilder
    var view: some View {
        switch self {
#if os(iOS)
        case .triangle_test:
            TriangleTestView()
        case .moving_bars:
            MovingBarsView()
        case .moving_bars_optimized:
            OptimizedMovingBarsView()
        case .moving_bars_4_vertices:
            FourVertBarsView()
#endif
        case .dominant_color_in_image:
            DominantColorView()
        }
    }
}

struct ContentView: View {
    
    @State private var selectedTab : Tabs? = nil
    @State private var shouldShowDebugInfo : Bool = false
    @ObservedObject private var metalRootCoordinator: MetalRootCoordinator = .shared
    
    var body: some View {
        ZStack {
            #if os(iOS)
            MetalRootContainer()
                .ignoresSafeArea()
                .allowsHitTesting(false)
            #endif
            
            NavigationSplitView {
                List(Tabs.allCases, id: \.self, selection: $selectedTab) { tab in
                    Text(tab.rawValue)
                }
            } detail: {
                selectedTab?.view
            }
#if os(iOS)
            if shouldShowDebugInfo {
                DebugInfoScreen()
            }
#endif
        }
        .onChange(of: selectedTab) { _, value in
            if value == nil {
                /// Reset the Command Buffer Execution Time when we return to nothing
                metalRootCoordinator.deviceInfo.commandBufferExecutionCall = CommandBufferExecutionCall(name: "", commandBufferExecutionTime: 0)
            }
        }
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    shouldShowDebugInfo.toggle()
                }) {
                    Label(
                        shouldShowDebugInfo ? "Hide Debug" : "Show Debug",
                        systemImage: shouldShowDebugInfo ? "eye.slash" : "eye"
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                }
                .buttonStyle(.plain)
            }
#endif
        }
    }
}

class MetalRootCoordinator: ObservableObject {
    
    static let shared = MetalRootCoordinator()
    
    @Published var deviceInfo: DeviceInfo = DeviceInfo()
    @Published var performanceState: PerformanceState? = nil
    
    @MainActor
    public func handleCommandBufferExecutionTime(
        _ cb: MTLCommandBuffer,
        from: String
    ) {
        let start = cb.gpuStartTime   // seconds (mach host time domain)
        let end   = cb.gpuEndTime
        guard start > 0, end > 0 else { return }   // still 0 if not available
        let gpuMs = (end - start) * 1000.0
        
        DispatchQueue.main.async {
            self.deviceInfo.commandBufferExecutionCall = CommandBufferExecutionCall(
                name: from,
                commandBufferExecutionTime: gpuMs
            )
        }
    }
}

#if os(iOS)
struct MetalRootContainer: UIViewRepresentable {
    
    @ObservedObject var metalRootCoordinator : MetalRootCoordinator = .shared
    
    func makeCoordinator() -> MetalRootContainerCoordinator {
        MetalRootContainerCoordinator()
    }
    
    func makeUIView(context: Context) -> some UIView {
        let mtkView = MTKView()
        mtkView.device = MetalContext.shared.device
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .invalid
        mtkView.clearColor = MTLClearColorMake(0,0,0,1)
        mtkView.preferredFramesPerSecond = 120
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = true
        mtkView.delegate = context.coordinator
        context.coordinator.metalRootCoordinator = self.metalRootCoordinator
        return mtkView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    class MetalRootContainerCoordinator: NSObject, MTKViewDelegate {
        
        private let ctx = MetalContext.shared
        var metalRootCoordinator: MetalRootCoordinator = .shared
        private var frameCount: Int = 0
        private var lastFPSUpdate: CFTimeInterval = CACurrentMediaTime()
        private var lastDeviceInfoUpdate: CFTimeInterval = CACurrentMediaTime()
        var currentFPS : Double = 0.0

        override init() {
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            
        }
        func draw(in view: MTKView) {
            updateFPS()
            let now = CACurrentMediaTime()
            if now - lastDeviceInfoUpdate >= 1.0 {
                updateDeviceInfo()
                lastDeviceInfoUpdate = now
            }
            metalRootCoordinator.performanceState = getPerformanceState()
        }
        
        private func updateFPS() {
            frameCount += 1
            let now = CACurrentMediaTime()
            
            if now - lastFPSUpdate >= 1.0 { // Update every second
                currentFPS = Double(frameCount) / (now - lastFPSUpdate)
                frameCount = 0
                lastFPSUpdate = now
            }
        }

        func getPerformanceState() -> PerformanceState {
            let device = UIDevice.current
            device.isBatteryMonitoringEnabled = true
            
            return PerformanceState(
                batteryLevel: device.batteryLevel,
                batteryState: device.batteryState.description,
                thermalState: ProcessInfo.processInfo.thermalState.description,
                isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled
            )
        }
        
        func updateDeviceInfo() {
            let device = UIDevice.current
            let processInfo = ProcessInfo.processInfo
            
            // Metal device info
            let metalDevice = ctx.device
            
            MetalRootCoordinator.shared.deviceInfo.deviceName = device.name
            
            MetalRootCoordinator.shared.deviceInfo.systemName = device.systemName
            MetalRootCoordinator.shared.deviceInfo.systemVersion = device.systemVersion
            MetalRootCoordinator.shared.deviceInfo.model = device.model
            
            // Metal capabilities
            MetalRootCoordinator.shared.deviceInfo.metalDeviceName = metalDevice.name
            MetalRootCoordinator.shared.deviceInfo.supportsFamily = [
                "Apple1": metalDevice.supportsFamily(.apple1),
                "Apple2": metalDevice.supportsFamily(.apple2),
                "Apple3": metalDevice.supportsFamily(.apple3),
                "Apple4": metalDevice.supportsFamily(.apple4),
                "Apple5": metalDevice.supportsFamily(.apple5),
                "Apple6": metalDevice.supportsFamily(.apple6),
                "Apple7": metalDevice.supportsFamily(.apple7),
                "Apple8": metalDevice.supportsFamily(.apple8),
                "Apple9": metalDevice.supportsFamily(.apple9),
            ]
            
            // Memory info
            MetalRootCoordinator.shared.deviceInfo.physicalMemory = processInfo.physicalMemory
            
            // Performance info
            MetalRootCoordinator.shared.deviceInfo.processorCount = processInfo.processorCount
            MetalRootCoordinator.shared.deviceInfo.activeProcessorCount = processInfo.activeProcessorCount
            
            // Metal specific
            MetalRootCoordinator.shared.deviceInfo.maxBufferLength = metalDevice.maxBufferLength
            MetalRootCoordinator.shared.deviceInfo.maxThreadsPerThreadgroup = metalDevice.maxThreadsPerThreadgroup
            
            // Current performance
            MetalRootCoordinator.shared.deviceInfo.currentFPS = currentFPS
        }
    }
}
#endif

#Preview {
    ContentView()
}
