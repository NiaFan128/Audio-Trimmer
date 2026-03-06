//
//  TrimmerFeatureTests.swift
//  AudioTrimmerTests
//
//  Created by Nia Fan on 2026/3/6.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import AudioTrimmerApp

@Suite("Default State")
struct DefaultStateTests {

    @Test("isPlaying defaults to false")
    func isPlayingDefault() {
        let state = TrimmerFeature.State(
            totalLength: 150,
            keyTimes: [],
            selectionRange: 0.0...0.2
        )
        #expect(state.isPlaying == false)
    }

    @Test("waveformSamples defaults to empty")
    func waveformSamplesDefault() {
        let state = TrimmerFeature.State(
            totalLength: 150,
            keyTimes: [],
            selectionRange: 0.0...0.2
        )
        #expect(state.waveformSamples.isEmpty)
    }

    @Test("currentTime starts at selectionRange.lowerBound * totalLength")
    func currentTimeDefault() {
        let state = TrimmerFeature.State(
            totalLength: 150,
            keyTimes: [],
            selectionRange: 0.2...0.4
        )
        #expect(state.currentTime == 0.2 * 150)
    }

    @Test("initialSelectionRange matches selectionRange on init")
    func initialSelectionRangeDefault() {
        let state = TrimmerFeature.State(
            totalLength: 150,
            keyTimes: [],
            selectionRange: 0.1...0.5
        )
        #expect(state.initialSelectionRange == state.selectionRange)
    }
}

@Suite("keyTimeTapped")
struct KeyTimeTappedTests {

    @Test("moves selection to tapped percentage, keeps same range length")
    func movesSelection() async {
        let store = await TestStore(initialState: TrimmerFeature.State(
            totalLength: 150,
            keyTimes: [],
            selectionRange: 0.0...0.2
        )) { TrimmerFeature() }

        await store.send(.keyTimeTapped(0.4)) {
            $0.selectionRange = 0.4...0.6
            $0.currentTime = 60.0
        }
    }

    @Test("clamps upper bound to 1.0 when tapped near end")
    func clampsUpperBound() async {
        let store = await TestStore(initialState: TrimmerFeature.State(
            totalLength: 150,
            keyTimes: [],
            selectionRange: 0.0...0.2
        )) { TrimmerFeature() }

        await store.send(.keyTimeTapped(0.9)) {
            $0.selectionRange = 0.9...1.0
            $0.currentTime = 135.0
        }
    }
}
