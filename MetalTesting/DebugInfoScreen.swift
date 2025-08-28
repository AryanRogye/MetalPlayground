//
//  DebugInfoScreen.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

import SwiftUI

struct DebugInfoScreen: View {
    
    @ObservedObject var metalRootCoordinator : MetalRootCoordinator
    
    var body: some View {
        FloatingDebugPanel(title: "Debug") {
            ScrollView {
                deviceInfo()
                performanceState()
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func deviceInfo() -> some View {
        VStack(alignment: .leading) {
            Text("Device Info:")
            Divider()
            if let d = metalRootCoordinator.deviceInfo {
                Text("\(d.currentFPS, specifier: "%.2f")")
                Divider()
                Text("Device Name: \(d.deviceName)")
                Divider()
                Text("System Name: \(d.systemName)")
                Divider()
                Text("System Version: \(d.systemVersion)")
                Divider()
                Text("Model: \(d.model)")
                Divider()
                Text("Metal Device Name: \(d.metalDeviceName)")
                Divider()
                Text("Physical Memory: \(d.physicalMemory) bytes")
                Divider()
                Text("Processor Count: \(d.processorCount)")
                Divider()
                Text("All Active Process Count: \(d.activeProcessorCount)")
                Divider()
                Text("Max Buffer Length \(d.maxBufferLength)")
                Divider()
                Text("Max Threads Per Thread Group \(d.maxThreadsPerThreadgroup)")
                Divider()
                ForEach(Array(d.supportsFamily.enumerated()), id: \.offset) { index, fam in
                    Text("\(fam.key): \(fam.value)")
                }
                Divider()
            }
        }
    }
    
    @ViewBuilder
    private func performanceState() -> some View {
        VStack(alignment: .leading) {
            Text("Performance State:")
            Divider()
            if let p = metalRootCoordinator.performanceState {
                Text("Battery Level: \(p.batteryLevel, specifier: "%.2f")")
                Divider()
                Text("Battery State: \(p.batteryState)")
                Divider()
                Text("Thermal State: \(p.thermalState)")
                Divider()
                Text("is Low Power On: \(p.isLowPowerModeEnabled)")
            }
        }
    }
}


struct FloatingDebugPanel<Content: View>: View {
    let minSize = CGSize(width: 180, height: 160)
    let maxSize = CGSize(width: 420, height: 700)
    
    @State private var size = CGSize(width: 260, height: 220)
    @State private var offset = CGSize(width: UIScreen.main.bounds.width - 260 - 16,
                                       height: UIScreen.main.bounds.height - (UIScreen.main.bounds.height / 2))
    @GestureState private var dragDelta: CGSize = .zero
    @GestureState private var resizeDelta: CGSize = .zero
    
    let title: String
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        GeometryReader { geo in
            panel
                .frame(width: clampedSize.width, height: clampedSize.height)
                .offset(clampedOffset(in: geo.size))
                .animation(.none, value: dragDelta)     // no lag while dragging
                .animation(.none, value: resizeDelta)
        }
        .ignoresSafeArea() // let it float anywhere
    }
    
    private var panel: some View {
        VStack(spacing: 0) {
            // MARK: - Title Bar (Dragging Gesture)
            HStack {
                Text(title).font(.headline)
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .gesture(dragGesture)
            
            // content
            content()
                .padding(10)
                .background(.thinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.25), lineWidth: 1)
        }
        .shadow(radius: 12, y: 6)
        .overlay(alignment: .bottomTrailing) {
            // resize handle
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 12, weight: .semibold))
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
                .offset(x: -6, y: -6)
                .gesture(resizeGesture)
                .accessibilityLabel("Resize")
        }
    }
    
    // MARK: Gestures
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragDelta) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                
                let newX = offset.width + value.translation.width
                let newY = offset.height + value.translation.height
                
                offset.width = newX
                offset.height = newY
            }
    }
    
    @State private var canvasSize: CGSize = .zero
    
    private var resizeGesture: some Gesture {
        DragGesture()
            .updating($resizeDelta) { value, state, _ in state = value.translation }
            .onEnded { value in
                size.width = clamp(size.width + value.translation.width, min: minSize.width, max: maxSize.width)
                size.height = clamp(size.height + value.translation.height, min: minSize.height, max: maxSize.height)
            }
    }
    
    // MARK: Clamp helpers
    private var clampedSize: CGSize {
        /// Clamping the Current Size of the Box or Debug View the User Made
        CGSize(
            width: clamp(size.width + resizeDelta.width, min: minSize.width, max: maxSize.width),
            height: clamp(size.height + resizeDelta.height, min: minSize.height, max: maxSize.height)
        )
    }
    
    private func clampedOffset(in canvas: CGSize) -> CGSize {
        // keep panel fully on-screen
        let w = clampedSize.width
        let h = clampedSize.height
        
        let dx = offset.width + dragDelta.width
        let dy = offset.height + dragDelta.height
        
        return CGSize(
            width: clamp(dx, min: 0, max: canvas.width - w),
            height: clamp(dy, min: 0, max: canvas.height - h)
        )
    }
    
    private func clamp<T: Comparable>(_ x: T, min lo: T, max hi: T) -> T { max(lo, min(x, hi)) }
}
