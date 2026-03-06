//
//  AudioTrimmerTests.swift
//  AudioTrimmerTests
//
//  Created by Nia Fan on 2026/2/28.
//

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
}
