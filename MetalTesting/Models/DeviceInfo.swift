//
//  DeviceInfo.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

import Metal

struct CommandBufferExecutionCall {
    var name : String
    var commandBufferExecutionTime : CFTimeInterval
}

// MARK: - Data Structures
struct DeviceInfo {
    
    var frameStartTime: CFTimeInterval
    var commandBufferExecutionCall : CommandBufferExecutionCall
    
    var cpuTimes: [Double]
    var gpuTimes: [Double]
    
    var deviceName: String
    var systemName: String
    var systemVersion: String
    var model: String
    
    var metalDeviceName: String
    var supportsFamily: [String: Bool]
    
    var physicalMemory: UInt64
    var processorCount: Int
    var activeProcessorCount: Int
    
    var maxBufferLength: Int
    var maxThreadsPerThreadgroup: MTLSize
    
    var currentFPS: Double
    
    public func commandBufferExecutionTimeText() -> String {
        if commandBufferExecutionCall.name.isEmpty {
            return "No Command Buffer Execution Call Made"
        } else {
            return """
            Command Buffer Execution Time
            |\(commandBufferExecutionCall.name)|
            \(commandBufferExecutionCall.commandBufferExecutionTime)
            """
        }
    }
    
    init(
        frameStartTime: CFTimeInterval,
        commandBufferExecutionCall: CommandBufferExecutionCall,
        cpuTimes: [Double],
        gpuTimes: [Double],
        deviceName: String,
        systemName: String,
        systemVersion: String,
        model: String,
        metalDeviceName: String,
        supportsFamily: [String: Bool],
        physicalMemory: UInt64,
        processorCount: Int,
        activeProcessorCount: Int,
        maxBufferLength: Int,
        maxThreadsPerThreadgroup: MTLSize,
        currentFPS: Double
    ) {
        self.frameStartTime = frameStartTime
        self.commandBufferExecutionCall = commandBufferExecutionCall
        self.cpuTimes = cpuTimes
        self.gpuTimes = gpuTimes
        self.deviceName = deviceName
        self.systemName = systemName
        self.systemVersion = systemVersion
        self.model = model
        self.metalDeviceName = metalDeviceName
        self.supportsFamily = supportsFamily
        self.physicalMemory = physicalMemory
        self.processorCount = processorCount
        self.activeProcessorCount = activeProcessorCount
        self.maxBufferLength = maxBufferLength
        self.maxThreadsPerThreadgroup = maxThreadsPerThreadgroup
        self.currentFPS = currentFPS
    }
    
    init() {
        self.frameStartTime = 0
        self.commandBufferExecutionCall = CommandBufferExecutionCall(name: "", commandBufferExecutionTime: 0)
        self.cpuTimes = []
        self.gpuTimes = []
        self.deviceName = ""
        self.systemName = ""
        self.systemVersion = ""
        self.model = ""
        self.metalDeviceName = ""
        self.supportsFamily = [:]
        self.physicalMemory = 0
        self.processorCount = 0
        self.activeProcessorCount = 0
        self.maxBufferLength = 0
        self.maxThreadsPerThreadgroup = MTLSize(width: 0, height: 0, depth: 0)
        self.currentFPS = 0
    }
}
