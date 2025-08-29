//
//  UIDevice.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

#if os(iOS)
import UIKit

// MARK: - Extensions for readable descriptions
extension UIDevice.BatteryState {
    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .unplugged: return "Unplugged"
        case .charging: return "Charging"
        case .full: return "Full"
        @unknown default: return "Unknown"
        }
    }
}

#endif
