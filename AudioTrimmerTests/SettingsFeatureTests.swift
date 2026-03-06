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

@Suite("editAudioTapped")
struct EditAudioTests {

    @Test("passes totalLength and keyTimes to TrimmerFeature")
    func passesState() async {
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
                selectionRange: 0.0...0.2
            )
        }
    }
}
