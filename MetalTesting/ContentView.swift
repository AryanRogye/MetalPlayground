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
    case triangle_test = "Triangle Test"
    case moving_bars   = "Moving Bars"
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .triangle_test:
            TriangleTestView()
        case .moving_bars:
            MovingBarsView()
        }
    }
}

struct ContentView: View {
    
    @State private var selectedTab : Tabs? = nil
    @State private var shouldShowDebugInfo : Bool = false
    
    @StateObject private var metalRootCoordinator : MetalRootCoordinator = MetalRootCoordinator()
    
    var body: some View {
        ZStack {
            MetalRootContainer(metalRootCoordinator : metalRootCoordinator)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            NavigationSplitView {
                List(Tabs.allCases, id: \.self, selection: $selectedTab) { tab in
                    Text(tab.rawValue)
                }
            } detail: {
                selectedTab?.view
            }
            
            if shouldShowDebugInfo {
                DebugInfoScreen(
                    metalRootCoordinator: metalRootCoordinator
                )
            }
        }
        .toolbar {
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
        }
    }
}

class MetalRootCoordinator: ObservableObject {
    @Published var deviceInfo: DeviceInfo? = nil
    @Published var performanceState: PerformanceState? = nil
}

struct MetalRootContainer: UIViewRepresentable {
    
    @ObservedObject var metalRootCoordinator : MetalRootCoordinator
    
    func makeCoordinator() -> MetalRootContainerCoordinator {
        MetalRootContainerCoordinator()
    }
    
    func makeUIView(context: Context) -> some UIView {
        let mtkView = MTKView()
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Error: Metal is not supported on this device.")
            return MTKView()
        }
        
        mtkView.device = device
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
        
        var metalRootCoordinator: MetalRootCoordinator?
        private var frameCount: Int = 0
        private var lastFPSUpdate: CFTimeInterval = 0
        var currentFPS : Double = 0.0

        override init() {
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            
        }
        func draw(in view: MTKView) {
            guard let metalRootCoordinator = metalRootCoordinator else { return }
            updateFPS()
            metalRootCoordinator.deviceInfo = getDeviceInfo()
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
        
        func getDeviceInfo() -> DeviceInfo {
            let device = UIDevice.current
            let processInfo = ProcessInfo.processInfo
            
            // Metal device info
            let metalDevice = MTLCreateSystemDefaultDevice()!
            
            return DeviceInfo(
                // Basic device info
                deviceName: device.name,
                systemName: device.systemName,
                systemVersion: device.systemVersion,
                model: device.model,
                
                // Metal capabilities
                metalDeviceName: metalDevice.name,
                supportsFamily: [
                    "Apple1": metalDevice.supportsFamily(.apple1),
                    "Apple2": metalDevice.supportsFamily(.apple2),
                    "Apple3": metalDevice.supportsFamily(.apple3),
                    "Apple4": metalDevice.supportsFamily(.apple4),
                    "Apple5": metalDevice.supportsFamily(.apple5),
                    "Apple6": metalDevice.supportsFamily(.apple6),
                    "Apple7": metalDevice.supportsFamily(.apple7),
                    "Apple8": metalDevice.supportsFamily(.apple8),
                    "Apple9": metalDevice.supportsFamily(.apple9),
                ],
                
                // Memory info
                physicalMemory: processInfo.physicalMemory,
                
                // Performance info
                processorCount: processInfo.processorCount,
                activeProcessorCount: processInfo.activeProcessorCount,
                
                // Metal specific
                maxBufferLength: metalDevice.maxBufferLength,
                maxThreadsPerThreadgroup: metalDevice.maxThreadsPerThreadgroup,
                
                // Current performance
                currentFPS: currentFPS
            )
        }
    }
}



#Preview {
    ContentView()
}
