//
//  MetalContext.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/31/25.
//

import Metal
import MetalKit

final class MetalContext {
    static let shared = MetalContext()
    let device: MTLDevice
    let queue: MTLCommandQueue
    let library: MTLLibrary
    private init() {
        device = MTLCreateSystemDefaultDevice()!
        queue  = device.makeCommandQueue()!
        library = try! device.makeDefaultLibrary(bundle: .main)
    }
}


enum ComputeCacheError: Error {
    case couldntMakeFunction
}

struct DebugOut {
    var value: SIMD4<Float>
}

struct Channels {
    /// R,G,B Will Keep Running Count On Amount
    var r: Float
    var g: Float
    var b: Float
    /// N Is Number We Can Use To Average It Out
    var n: Float
}

final class ComputeCache {
    static let shared = ComputeCache()
    private var ctx: MetalContext = .shared
    private var cache: [String: MTLComputePipelineState] = [:]
    
    
    /// Function already needs to throw something, so might as well
    /// throw some of our errors as well
    func pipeline(_ name: String) throws -> MTLComputePipelineState {
        if let p = cache[name] {
            print("Pipeline Already Exists")
            return p
        }
        let lib = ctx.library
        
        guard let fn = lib.makeFunction(name: name) else {
            throw ComputeCacheError.couldntMakeFunction
        }
        
        let pso = try ctx.device.makeComputePipelineState(function: fn)
        cache[name] = pso
        return pso
    }
}
