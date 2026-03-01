//
//  TrimmerFeature.swift
//  ios-audio-trimmer
//
//  Created by Nia Fan on 2026/3/1.
//

import ComposableArchitecture
import Foundation

// MARK: - Domain Models

struct KeyTimePoint: Equatable, Identifiable, Sendable {
    let id: UUID
    var percentage: Double
}

@Reducer
struct TrimmerFeature {
    
    @ObservableState
    struct State: Equatable {
        var totalLength: TimeInterval
        var keyTimes: IdentifiedArrayOf<KeyTimePoint>
        var selectionRange: ClosedRange<Double>
        var currentTime: TimeInterval
        var isPlaying: Bool
        
        static var mock: State {
            State(
                totalLength: 150.0,
                keyTimes: [
                    KeyTimePoint(id: UUID(), percentage: 0.0),
                    KeyTimePoint(id: UUID(), percentage: 0.25),
                    KeyTimePoint(id: UUID(), percentage: 0.5),
                    KeyTimePoint(id: UUID(), percentage: 0.75),
                    KeyTimePoint(id: UUID(), percentage: 1.0)
                ],
                selectionRange: 0.2...0.8,
                currentTime: 0.0,
                isPlaying: false
            )
        }
    }
    
    enum Action: Equatable, Sendable { case onAppear }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            }
        }
    }
}

