//
//  DominantColor_iOS.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/29/25.
//

import SwiftUI

#if os(iOS)
struct DominantColorView_iOS: View {
    @State private var isPickingImage: Bool = false
    @State private var dominantColorCPU: UIColor?
    @State private var dominantColorGPU: UIColor?
    @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack {
            imagePicker
            dominantColorCPUView()
            dominantColorGPUView()
            Spacer()
        }
        // iOS: present as a sheet
        .sheet(isPresented: $isPickingImage) {
            ImagePicker(image: $selectedImage)
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
                        .fill(Color(uiColor: dominantColorGPU))
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
                        .fill(Color(uiColor: dominantColorCPU))
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
                Image(uiImage: image)
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

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
#endif
