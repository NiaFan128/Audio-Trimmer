//
//  AudioClient.swift
//  AudioTrimmer
//
//  Created by Nia Fan on 2026/3/6.
//

import ComposableArchitecture
import Foundation

struct AudioMetadata: Equatable, Sendable {
    var duration: TimeInterval
    /// Normalized amplitude samples (0.0–1.0). Empty = SF Symbol fallback.
    var waveformSamples: [Float]
}

struct AudioClient: Sendable {
    var loadMetadata: @Sendable (URL) async throws -> AudioMetadata
}

extension AudioClient: DependencyKey {
    static let liveValue = AudioClient(
        loadMetadata: { _ in throw AudioClientError.notImplemented }
    )

    static let previewValue = AudioClient(
        loadMetadata: { _ in AudioMetadata(duration: 150, waveformSamples: []) }
    )

    static let testValue = AudioClient(
        loadMetadata: { _ in AudioMetadata(duration: 0, waveformSamples: []) }
    )
}

extension DependencyValues {
    var audioClient: AudioClient {
        get { self[AudioClient.self] }
        set { self[AudioClient.self] = newValue }
    }
}

enum AudioClientError: Error {
    case notImplemented
    case loadFailed(URL)
}
