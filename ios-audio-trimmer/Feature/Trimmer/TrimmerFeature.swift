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
        let initialSelectionRange: ClosedRange<Double>
        var currentTime: TimeInterval
        var isPlaying: Bool

        init(
            totalLength: TimeInterval,
            keyTimes: IdentifiedArrayOf<KeyTimePoint>,
            selectionRange: ClosedRange<Double>,
            currentTime: TimeInterval,
            isPlaying: Bool
        ) {
            self.totalLength = totalLength
            self.keyTimes = keyTimes
            self.selectionRange = selectionRange
            self.initialSelectionRange = selectionRange
            self.currentTime = currentTime
            self.isPlaying = isPlaying
        }

        static var mock: State {
            State(
                totalLength: 150.0,
                keyTimes: [
                    KeyTimePoint(id: UUID(), percentage: 0.1),
                    KeyTimePoint(id: UUID(), percentage: 0.25),
                    KeyTimePoint(id: UUID(), percentage: 0.4),
                    KeyTimePoint(id: UUID(), percentage: 0.65),
                    KeyTimePoint(id: UUID(), percentage: 0.8),
                    KeyTimePoint(id: UUID(), percentage: 0.9)
                ],
                selectionRange: 0.2...0.4,
                currentTime: 0.0,
                isPlaying: false
            )
        }
    }
    
    enum Action {
        case onAppear
        case playButtonTapped
        case resetTapped
        case timerTick
        case keyTimeTapped(Double)
    }

    private enum CancelID { case timer }

    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none

            case .playButtonTapped:
                state.isPlaying.toggle()
                if state.isPlaying {
                    return .run { send in
                        while true {
                            try await clock.sleep(for: .seconds(0.1))
                            await send(.timerTick)
                        }
                    }
                    .cancellable(id: CancelID.timer, cancelInFlight: true)
                } else {
                    return .cancel(id: CancelID.timer)
                }

            case .resetTapped:
                state.isPlaying = false
                state.selectionRange = state.initialSelectionRange
                state.currentTime = state.initialSelectionRange.lowerBound * state.totalLength
                return .cancel(id: CancelID.timer)

            case let .keyTimeTapped(percentage):
                let rangeLength = state.initialSelectionRange.upperBound - state.initialSelectionRange.lowerBound
                let newUpper = min(percentage + rangeLength, 1.0)
                state.selectionRange = percentage...newUpper
                state.currentTime = percentage * state.totalLength
                return .none

            case .timerTick:
                let startTime = state.selectionRange.lowerBound * state.totalLength
                let endTime = state.selectionRange.upperBound * state.totalLength
                state.currentTime += 0.1
                if state.currentTime >= endTime {
                    state.currentTime = startTime
                }
                return .none
            }
        }
    }
}

