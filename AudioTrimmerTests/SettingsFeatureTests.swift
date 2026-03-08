//
//  SettingsFeatureTests.swift
//  AudioTrimmerTests
//
//  Created by Nia Fan on 2026/2/28.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import AudioTrimmerApp

@Suite("formatMMSS")
struct FormatMMSSTests {

    @Test("4 digits → inserts colon", arguments: [
        ("0230", "02:30"),
        ("0000", "00:00"),
        ("9959", "99:59"),
    ])
    func fourDigits(input: String, expected: String) {
        #expect(SettingsFeature.formatMMSS(input) == expected)
    }

    @Test("less than 3 digits → no colon", arguments: [
        ("", ""),
        ("0", "0"),
        ("02", "02"),
    ])
    func lessThanThreeDigits(input: String, expected: String) {
        #expect(SettingsFeature.formatMMSS(input) == expected)
    }

    @Test("seconds > 59 → clamped to 59", arguments: [
        ("0260", "02:59"),
        ("0290", "02:59"),
    ])
    func secondsClamped(input: String, expected: String) {
        #expect(SettingsFeature.formatMMSS(input) == expected)
    }

    @Test("seconds == 59 → valid, not clamped")
    func secondsBoundary() {
        #expect(SettingsFeature.formatMMSS("0259") == "02:59")
    }
}

@Suite("totalLength")
struct TotalLengthTests {

    @Test("valid mm:ss → correct seconds", arguments: [
        ("02:30", 150.0),
        ("00:00", 0.0),
        ("01:00", 60.0),
        ("99:59", 5999.0),
    ])
    func validInput(text: String, expected: TimeInterval) {
        var state = SettingsFeature.State()
        state.totalLengthText = text
        #expect(state.totalLength == expected)
    }

    @Test("incomplete input → 0", arguments: [
        "", "02", "0230"
    ])
    func incompleteInput(text: String) {
        var state = SettingsFeature.State()
        state.totalLengthText = text
        #expect(state.totalLength == 0)
    }
}

@Suite("timeString")
struct TimeStringTests {

    @Test("percentage × totalLength → mm:ss", arguments: [
        (0.25, 150.0, "00:37"),
        (0.50, 60.0, "00:30"),
        (0.0, 150.0, "00:00"),
        (1.0, 150.0, "02:30"),
    ])
    func validOutput(percentage: Double, totalLength: TimeInterval, expected: String) {
        #expect(SettingsFeature.timeString(percentage: percentage, totalLength: totalLength) == expected)
    }

    @Test("totalLength 0 → --:--")
    func zeroTotalLength() {
        #expect(SettingsFeature.timeString(percentage: 0.5, totalLength: 0) == "--:--")
    }
}

@Suite("Key Times")
struct KeyTimesTests {

    @Test("add first key time → 10%")
    func addFirst() async {
        var initial = SettingsFeature.State()
        initial.keyTimes = []
        let store = await TestStore(initialState: initial) {
            SettingsFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        await store.send(.addKeyTimePointTapped) {
            $0.keyTimes = [KeyTimePoint(id: UUID(0), percentage: 0.10)]
        }
    }

    @Test("add increments by 10% from last")
    func addIncrement() async {
        var initial = SettingsFeature.State()
        initial.keyTimes = [KeyTimePoint(id: UUID(1), percentage: 0.50)]
        let store = await TestStore(initialState: initial) {
            SettingsFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        await store.send(.addKeyTimePointTapped) {
            $0.keyTimes.append(KeyTimePoint(id: UUID(0), percentage: 0.60))
        }
    }

    @Test("add clamps to 100% when last is 95%")
    func addClampsAt100() async {
        var initial = SettingsFeature.State()
        initial.keyTimes = [KeyTimePoint(id: UUID(1), percentage: 0.95)]
        let store = await TestStore(initialState: initial) {
            SettingsFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        await store.send(.addKeyTimePointTapped) {
            $0.keyTimes.append(KeyTimePoint(id: UUID(0), percentage: 1.0))
        }
    }

    @Test("add does nothing when last is 100%")
    func addBlockedAt100() async {
        var initial = SettingsFeature.State()
        initial.keyTimes = [KeyTimePoint(id: UUID(0), percentage: 1.0)]
        let store = await TestStore(initialState: initial) { SettingsFeature() }
        await store.send(.addKeyTimePointTapped)
    }

    @Test("delete removes correct item")
    func delete() async {
        let id = UUID(0)
        var initial = SettingsFeature.State()
        initial.keyTimes = [
            KeyTimePoint(id: id, percentage: 0.10),
            KeyTimePoint(id: UUID(1), percentage: 0.25),
        ]
        let store = await TestStore(initialState: initial) { SettingsFeature() }
        await store.send(.deleteKeyTime(IndexSet(integer: 0))) {
            $0.keyTimes.remove(id: id)
        }
    }

    @Test("update clamps below 0")
    func updateClampMin() async {
        let id = UUID(0)
        var initial = SettingsFeature.State()
        initial.keyTimes = [KeyTimePoint(id: id, percentage: 0.10)]
        let store = await TestStore(initialState: initial) { SettingsFeature() }
        await store.send(.keyTimeUpdated(id: id, percentage: -0.10)) {
            $0.keyTimes[id: id]?.percentage = 0.0
        }
    }

    @Test("update clamps above 100%")
    func updateClampMax() async {
        let id = UUID(0)
        var initial = SettingsFeature.State()
        initial.keyTimes = [KeyTimePoint(id: id, percentage: 0.80)]
        let store = await TestStore(initialState: initial) { SettingsFeature() }
        await store.send(.keyTimeUpdated(id: id, percentage: 1.50)) {
            $0.keyTimes[id: id]?.percentage = 1.0
        }
    }

    @Test("update sorts by percentage")
    func updateSorts() async {
        let id = UUID(0)
        var initial = SettingsFeature.State()
        initial.keyTimes = [
            KeyTimePoint(id: id, percentage: 0.80),
            KeyTimePoint(id: UUID(1), percentage: 0.50),
        ]
        let store = await TestStore(initialState: initial) { SettingsFeature() }
        await store.send(.keyTimeUpdated(id: id, percentage: 0.20)) {
            $0.keyTimes[id: id]?.percentage = 0.20
            $0.keyTimes.sort { $0.percentage < $1.percentage }
        }
    }
}

@Suite("Unhappy Paths")
struct UnhappyPathTests {

    @Test("duplicate percentages — update one to different value still sorts correctly")
    func duplicatePercentageSort() async {
        let id0 = UUID(0)
        let id1 = UUID(1)
        var initial = SettingsFeature.State()
        initial.keyTimes = [
            KeyTimePoint(id: id0, percentage: 0.50),
            KeyTimePoint(id: id1, percentage: 0.50),
        ]
        let store = await TestStore(initialState: initial) { SettingsFeature() }
        await store.send(.keyTimeUpdated(id: id1, percentage: 0.30)) {
            $0.keyTimes[id: id1]?.percentage = 0.30
            $0.keyTimes.sort { $0.percentage < $1.percentage }
        }
    }

    @Test("editAudioTapped with totalLength 0 does not crash")
    func zeroTotalLength() async {
        var initial = SettingsFeature.State()
        initial.totalLengthText = "00:00"
        initial.keyTimes = []
        let store = await TestStore(initialState: initial) { SettingsFeature() }
        await store.send(.editAudioTapped) {
            $0.trimmer = TrimmerFeature.State(
                totalLength: 0,
                keyTimes: [],
                selectionRange: 0.0...0.2
            )
        }
    }
}

@Suite("editAudioTapped")
struct EditAudioTests {

    @Test("selectionRange centers on first keyTime")
    func selectionRangeCenteredOnFirstKeyTime() async {
        let keyTimes: IdentifiedArrayOf<KeyTimePoint> = [
            KeyTimePoint(id: UUID(0), percentage: 0.25),
            KeyTimePoint(id: UUID(1), percentage: 0.50),
        ]
        var initial = SettingsFeature.State()
        initial.totalLengthText = "02:30"
        initial.keyTimes = keyTimes
        let store = await TestStore(initialState: initial) { SettingsFeature() }
        await store.send(.editAudioTapped) {
            $0.trimmer = TrimmerFeature.State(
                totalLength: 150.0,
                keyTimes: keyTimes,
                selectionRange: 0.15...0.35
            )
        }
    }

    @Test("selectionRange defaults to 0.0...0.2 when no keyTimes")
    func selectionRangeDefaultWhenEmpty() async {
        var initial = SettingsFeature.State()
        initial.totalLengthText = "02:30"
        initial.keyTimes = []
        let store = await TestStore(initialState: initial) { SettingsFeature() }
        await store.send(.editAudioTapped) {
            $0.trimmer = TrimmerFeature.State(
                totalLength: 150.0,
                keyTimes: [],
                selectionRange: 0.0...0.2
            )
        }
    }
}

@Suite("Integration: Settings → Trimmer", .serialized)
struct SettingsTrimmerIntegrationTests {

    @Test("operate in trimmer then dismiss — parent state restored")
    func operateAndDismiss() async {
        let clock = TestClock()
        let keyTimes: IdentifiedArrayOf<KeyTimePoint> = [
            KeyTimePoint(id: UUID(0), percentage: 0.25),
        ]
        var initial = SettingsFeature.State()
        initial.totalLengthText = "01:00"
        initial.keyTimes = keyTimes
        let store = await TestStore(initialState: initial) {
            SettingsFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        // enter trimmer — keyTimes should match
        await store.send(.editAudioTapped) {
            $0.trimmer = TrimmerFeature.State(
                totalLength: 60.0,
                keyTimes: keyTimes,
                selectionRange: 0.15...0.35
            )
        }
        #expect(store.state.trimmer?.keyTimes == keyTimes)

        // operate inside trimmer — tap a key time
        await store.send(\.trimmer.presented.keyTimeTapped, 0.5) {
            $0.trimmer?.selectionRange = 0.5...0.7
            $0.trimmer?.currentTime = 30.0
        }

        // dismiss trimmer
        await store.send(\.trimmer.dismiss) {
            $0.trimmer = nil
        }

        // parent state unchanged
        #expect(store.state.keyTimes == keyTimes)
        #expect(store.state.totalLengthText == "01:00")
    }

    @Test("play in trimmer then dismiss — timer effect cancelled")
    func playAndDismiss() async {
        let clock = TestClock()
        var initial = SettingsFeature.State()
        initial.totalLengthText = "01:00"
        initial.keyTimes = []
        let store = await TestStore(initialState: initial) {
            SettingsFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.editAudioTapped) {
            $0.trimmer = TrimmerFeature.State(
                totalLength: 60.0,
                keyTimes: [],
                selectionRange: 0.0...0.2
            )
        }

        // start playback
        await store.send(\.trimmer.presented.playButtonTapped) {
            $0.trimmer?.isPlaying = true
        }
        await clock.advance(by: .seconds(0.1))
        await store.receive(\.trimmer.presented.timerTick) {
            $0.trimmer?.currentTime = 0.1
        }

        // dismiss while playing — timer should be cancelled
        await store.send(\.trimmer.dismiss) {
            $0.trimmer = nil
        }

        // advance after dismiss — no timerTick received
        await clock.advance(by: .seconds(0.5))
    }
}
