//
//  DominantColor.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/29/25.
//

import SwiftUI
import Accelerate

struct DominantColorView: View {
    var body: some View {
#if os(iOS)
        DominantColorView_iOS()
#else
        DominantColorView_macOS()
#endif
    }
}

#Preview {
    DominantColorView()
}
