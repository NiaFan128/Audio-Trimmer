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

@Suite("Playback Controls")
struct PlaybackControlTests {

    @Test("play sets isPlaying to true")
    func play() async {
        let store = await TestStore(initialState: TrimmerFeature.State(
            totalLength: 150,
            keyTimes: [],
            selectionRange: 0.0...0.2
        )) { TrimmerFeature() } withDependencies: {
            $0.continuousClock = ImmediateClock()
        }
        await store.send(.playButtonTapped) {
            $0.isPlaying = true
        }
        await store.send(.playButtonTapped) {
            $0.isPlaying = false
        }
    }

    @Test("pause sets isPlaying to false")
    func pause() async {
        var initial = TrimmerFeature.State(
            totalLength: 150,
            keyTimes: [],
            selectionRange: 0.0...0.2
        )
        initial.isPlaying = true
        let store = await TestStore(initialState: initial) {
            TrimmerFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
        }
        await store.send(.playButtonTapped) {
            $0.isPlaying = false
        }
    }

    @Test("reset restores selectionRange and currentTime, stops playback")
    func reset() async {
        let store = await TestStore(initialState: TrimmerFeature.State(
            totalLength: 150,
            keyTimes: [],
            selectionRange: 0.0...0.2
        )) { TrimmerFeature() } withDependencies: {
            $0.continuousClock = ImmediateClock()
        }
        await store.send(.playButtonTapped) {
            $0.isPlaying = true
        }
        await store.send(.resetTapped) {
            $0.isPlaying = false
            $0.selectionRange = 0.0...0.2
            $0.currentTime = 0.0
        }
    }
}

@Suite("timerTick")
struct TimerTickTests {

    @Test("advances currentTime by 0.1")
    func advances() async {
        var initial = TrimmerFeature.State(
            totalLength: 150,
            keyTimes: [],
            selectionRange: 0.0...0.2
        )
        initial.currentTime = 10.0
        let store = await TestStore(initialState: initial) { TrimmerFeature() }
        await store.send(.timerTick) {
            $0.currentTime = 10.1
        }
    }

    @Test("wraps back to startTime when reaching endTime")
    func wraps() async {
        // selectionRange 0.0...0.2, totalLength 150 → endTime = 30.0
        var initial = TrimmerFeature.State(
            totalLength: 150,
            keyTimes: [],
            selectionRange: 0.0...0.2
        )
        initial.currentTime = 29.9
        let store = await TestStore(initialState: initial) { TrimmerFeature() }
        await store.send(.timerTick) {
            $0.currentTime = 0.0  // wraps to startTime
        }
    }
}
