//
//  Vertex.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

struct Vertex {
    var pos: SIMD2<Float>
}

struct Uniforms {
    var time: Float
}
struct BarUniforms {
    var time: Float
    var shouldAnimate: Float
}

struct OptimizedBarUniforms {
    /// Represents Number of Bars to Render
    var number: Float
    /// Time From When We Started
    var time: Float
    /// If We Shoudl Animate or Not
    var shouldAnimate: Float
}
struct FourBarUniforms {
    /// Represents Number of Bars to Render
    var number: Float
    var shouldAnimate: Float
    var time: Float
    /// If We Shoudl Animate or Not
    var gap: Float = 0.3
}

struct TriangleInfo {
    var min: Float
    var max: Float
    var time: Float
    var speed: Float
}
