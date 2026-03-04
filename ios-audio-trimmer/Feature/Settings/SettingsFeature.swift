//
//  SettingsFeature.swift
//  ios-audio-trimmer
//
//  Created by Nia Fan on 2026/3/4.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SettingsFeature {

    @ObservableState
    struct State: Equatable {
        var totalLengthText: String = "02:30"
        var keyTimes: IdentifiedArrayOf<KeyTimePoint> = [
            KeyTimePoint(id: UUID(), percentage: 0.10),
            KeyTimePoint(id: UUID(), percentage: 0.25),
            KeyTimePoint(id: UUID(), percentage: 0.40),
            KeyTimePoint(id: UUID(), percentage: 0.65),
            KeyTimePoint(id: UUID(), percentage: 0.80),
        ]
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case addKeyTimePointTapped
        case deleteKeyTime(IndexSet)
        case editAudioTapped
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .addKeyTimePointTapped:
                let lastPct = state.keyTimes.map(\.percentage).max() ?? 0.0
                guard lastPct < 1.0 else { return .none }
                let newPct = min(lastPct + 0.10, 1.0)
                state.keyTimes.append(KeyTimePoint(id: UUID(), percentage: newPct))
                return .none

            case let .deleteKeyTime(indices):
                for index in indices.reversed() {
                    state.keyTimes.remove(at: index)
                }
                return .none

            case .editAudioTapped:
                return .none
            }
        }
    }
}
