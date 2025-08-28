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

struct TriangleInfo {
    var min: Float
    var max: Float
    var time: Float
    var speed: Float
}
