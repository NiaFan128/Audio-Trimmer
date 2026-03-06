//
//  TrimmerFeature.swift
//  ios-audio-trimmer
//
//  Created by Nia Fan on 2026/3/1.
//

import ComposableArchitecture
import Foundation

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
        /// Normalized amplitude samples (0.0–1.0). Empty = SF Symbol fallback.
        var waveformSamples: [Float]

        init(
            totalLength: TimeInterval,
            keyTimes: IdentifiedArrayOf<KeyTimePoint>,
            selectionRange: ClosedRange<Double>,
            isPlaying: Bool = false,
            waveformSamples: [Float] = []
        ) {
            self.totalLength = totalLength
            self.keyTimes = keyTimes
            self.selectionRange = selectionRange
            self.initialSelectionRange = selectionRange
            self.isPlaying = isPlaying
            self.currentTime = selectionRange.lowerBound * totalLength
            self.waveformSamples = waveformSamples
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
                selectionRange: 0.2...0.4
            )
        }
    }
    
    enum Action {
        case onAppear
        case audioMetadataLoaded(AudioMetadata)
        case playButtonTapped
        case resetTapped
        case timerTick
        case keyTimeTapped(Double)
        case playheadDragged(Double)
        case selectionWindowMoved(to: Double)
    }

    private enum CancelID { case timer }

    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none

            case let .audioMetadataLoaded(metadata):
                state.totalLength = metadata.duration
                state.waveformSamples = metadata.waveformSamples
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
                let newUpper = min(percentage + rangeLength, 1.0).rounded()
                let shift = percentage - state.selectionRange.lowerBound
                state.selectionRange = percentage...newUpper
                state.currentTime = (state.currentTime + shift * state.totalLength).rounded(places: 2)
                return .none

            case let .playheadDragged(percentage):
                let clamped = min(1.0, max(0.0, percentage))
                state.currentTime = (clamped * state.totalLength).rounded(places: 2)
                return .none

            case let .selectionWindowMoved(to: newLower):
                let rangeWidth = state.selectionRange.upperBound - state.selectionRange.lowerBound
                let clampedLower = min(1.0 - rangeWidth, max(0.0, newLower)).rounded()
                let shift = clampedLower - state.selectionRange.lowerBound
                state.selectionRange = clampedLower...(clampedLower + rangeWidth).rounded()
                state.currentTime = (state.currentTime + shift * state.totalLength).rounded(places: 2)
                return .none

            case .timerTick:
                let startTime = (state.selectionRange.lowerBound * state.totalLength).rounded(places: 2)
                let endTime = (state.selectionRange.upperBound * state.totalLength).rounded(places: 2)
                state.currentTime = (state.currentTime + 0.1).rounded(places: 2)
                if state.currentTime >= endTime {
                    state.currentTime = startTime
                }
                return .none
            }
        }
    }
}

