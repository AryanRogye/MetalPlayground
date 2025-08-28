//
//  ProcessInfo.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

import SwiftUI

extension ProcessInfo.ThermalState {
    var description: String {
        switch self {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
}
