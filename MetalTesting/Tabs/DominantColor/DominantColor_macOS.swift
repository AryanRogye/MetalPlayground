//
//  DominantColor_macOS.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/29/25.
//

import SwiftUI

#if os(macOS)
struct DominantColorView_macOS: View {
    @State private var isPickingImage: Bool = false
    
    @State private var dominantColorCPU: NSColor?
    @State private var dominantColorGPU: NSColor?
    
    @State private var selectedImage: NSImage?
    
    var body: some View {
        VStack {
            imagePicker
            
            dominantColorCPUView()
            
            dominantColorGPUView()
            
            Spacer()
        }
        // iOS: present as a sheet
        .background {
            if isPickingImage {
                ImagePicker(image: $selectedImage, onComplete: {
                    isPickingImage = false
                })
            }
        }
    }
    
    @ViewBuilder
    private func dominantColorGPUView() -> some View {
        if let image = selectedImage {
            HStack {
                Button(action: {
                    dominantColorGPU = DominantColorExtractionGPU.getDominantColor(from: image)
                }) {
                    Text("Get Dominant Color (GPU")
                }
                Spacer()
                if let dominantColorGPU = dominantColorGPU {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: dominantColorGPU))
                        .frame(width: 80, height: 80)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 80)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func dominantColorCPUView() -> some View {
        if let image = selectedImage {
            HStack {
                Button(action: {
                    dominantColorCPU = DominantColorExtraction.getDominantColor(from: image)
                }) {
                    Text("Get Dominant Color (CPU")
                }
                Spacer()
                if let dominantColorCPU = dominantColorCPU {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: dominantColorCPU))
                        .frame(width: 80, height: 80)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 80)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
            }
            .padding()
        }
    }
    
    private var imagePicker: some View {
        HStack {
            Button(action: { isPickingImage = true }) {
                Text("Pick Image")
            }
            
            Spacer()
            
            if let image = selectedImage {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: 80, height: 80)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 80)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
        }
        .padding()
    }
}

struct ImagePicker: NSViewControllerRepresentable {
    @Binding var image: NSImage?
    var onComplete: () -> Void = {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSViewController(context: Context) -> NSViewController { NSViewController() }
    
    func updateNSViewController(_ vc: NSViewController, context: Context) {
        guard !context.coordinator.didPresent else { return }
        context.coordinator.didPresent = true
        
        let panel = NSOpenPanel()
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [
                .png, .jpeg, .tiff, .gif, .bmp, .heic, .heif
            ]
        } else {
            panel.allowedFileTypes = ["png","jpg","jpeg","tiff","gif","bmp"]
        }
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        panel.begin { response in
            defer { onComplete() }
            guard response == .OK, let url = panel.urls.first else { return }
            
            // More reliable load path than NSImage(contentsOf:)
            if let data = try? Data(contentsOf: url),
               let picked = NSImage(data: data) {
                self.image = picked
            } else if let picked = NSImage(contentsOf: url) { // fallback
                self.image = picked
            }
        }
    }
    
    class Coordinator: NSObject {
        var parent: ImagePicker
        var didPresent = false
        init(_ parent: ImagePicker) { self.parent = parent }
    }
}

#endif
