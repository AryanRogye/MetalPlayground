//
//  TriangleTest.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

import SwiftUI
import Combine
import Metal
import MetalKit

#if os(iOS)
struct TriangleTestView: View {
    
    @ObservedObject var metalBackgroundParams = MetalBackgroundParameters.shared
    @StateObject var triangleTestMetalCoordinator  = TriangleTestMetalCoordinator()

    @State private var isEditingMin: Bool = false
    @State private var isEditingMax: Bool = false
    @State private var lastMin: Float = 0
    @State private var lastMax: Float = 0
    
    var body: some View {
        VStack {
            TriangleTestMetal(
                TriangleTestMetalCoordinator: triangleTestMetalCoordinator
            )
            .onAppear {
                triangleTestMetalCoordinator.resume()
            }
            .onDisappear {
                triangleTestMetalCoordinator.pause()
            }
            .padding()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Speed")
                    .font(.headline)
                changeMin
                changeMax
                
                Slider(
                    value: $metalBackgroundParams.speed,
                    in: 0...1
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var changeMin: some View {
        TextChange(label: "Min",value: $metalBackgroundParams.minimum)
    }
    private var changeMax: some View {
        TextChange(label: "Max", value: $metalBackgroundParams.maximum)
    }
}

struct TextChange: View {
    
    var label: String
    @Binding var value : Float
    @State private var isEditing = false
    @State private var lastValue : Float = 0.0
    
    var body: some View {
        if isEditing {
            HStack(alignment: .center) {
                TextField("Minimum", value: $lastValue, format: .number.precision(.fractionLength(2)))
                Button(action: {
                    lastValue = 0.0
                    isEditing = false
                }) {
                    Image(systemName: "xmark")
                }
                Button(action: {
                    value = lastValue
                    lastValue = 0.0
                    isEditing = false
                }) {
                    Image(systemName: "checkmark")
                }
            }
        } else {
            Button(action: {
                isEditing = true
                lastValue = value
            }) {
                Text("\(label): \(value, specifier: "%.2f")")
            }
            .buttonStyle(.plain)
        }
    }
}

/// From What im understanding theres 2 things that we need
/// Vertex Shader, and a Fragment Shader

/*
 Vertex Shader:
 Input: The 3D positions (vertices).
 Job: Transform them (rotate, move, scale, project onto screen).
 Output: “This pixel of the triangle will land here on screen.”
 */

/*
 Fragment Shader:
 Input: Each pixel inside the thing we make.
 Job: Decide its color.
 Output: The final RGBA value for that pixel.
 */

class MetalBackgroundParameters: ObservableObject {
    static let shared = MetalBackgroundParameters()
    @Published var speed : Float = 0.1
    
    @Published var minimum : Float = 0.2
    @Published var maximum : Float = 1.0
}


#endif
