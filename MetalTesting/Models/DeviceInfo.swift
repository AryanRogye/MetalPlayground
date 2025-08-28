//
//  DeviceInfo.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

import Metal

// MARK: - Data Structures
struct DeviceInfo {
    let deviceName: String
    let systemName: String
    let systemVersion: String
    let model: String
    
    let metalDeviceName: String
    let supportsFamily: [String: Bool]
    
    let physicalMemory: UInt64
    let processorCount: Int
    let activeProcessorCount: Int
    
    let maxBufferLength: Int
    let maxThreadsPerThreadgroup: MTLSize
    
    let currentFPS: Double
}
