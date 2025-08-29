//
//  OptimizedMovingBars.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

import SwiftUI

#if os(iOS)

struct OptimizedMovingBarsView: View {
    /// TODO CHANGE NAME
    @StateObject private var barCoordinator: BarCoordinator = BarCoordinator()
    
    var body: some View {
        VStack {
            Spacer()
            /// When they internally change the heights they should be aligned to the
            /// bottom so they look like their going into it
            OptimizedBarView(
                barCoordinator: barCoordinator
            )
            .frame(alignment: .center)
            
            Spacer()
            HStack {
                decrementButton
                Spacer()
                playButton
                Spacer()
                incrementButton
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private var incrementButton: some View {
        Button(action: {
            barCoordinator.incrementBarNumber()
        }) {
            Image(systemName: "plus")
                .resizable()
                .frame(width: 50, height: 50)
        }
    }
    
    private var decrementButton: some View {
        Button(action: {
            barCoordinator.decrementBarNumber()
        }) {
            Image(systemName: "minus")
                .resizable()
                .frame(width: 50, height: 10)
        }
    }
    
    private var playButton: some View {
        Button(action: {
            withAnimation(.snappy) {
                barCoordinator.toggleMove.toggle()
            }
        }) {
            Image(systemName: barCoordinator.toggleMove ? "pause.fill" : "play.fill")
                .resizable()
                .frame(width: 50, height: 50)
        }
    }
}


class OptimizedBarCoordinator: ObservableObject {
    @Published var toggleMove: Bool = false
    @Published var barNumber : Int = 3
    
    private let minBars = 1
    private let maxBars = 100
    
    public func decrementBarNumber() {
        barNumber = max(barNumber - 1, minBars)
    }
    
    public func incrementBarNumber() {
        barNumber = min(barNumber + 1, maxBars)
    }
}

#Preview {
    OptimizedMovingBarsView()
}

#endif
