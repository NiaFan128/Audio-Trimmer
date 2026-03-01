//
//  TrimmerView.swift
//  ios-audio-trimmer
//
//  Created by Nia Fan on 2026/3/1.
//

import ComposableArchitecture
import SwiftUI

// MARK: - TrimmerView

struct TrimmerView: View {
    @Bindable var store: StoreOf<TrimmerFeature>

    var body: some View {
        VStack(spacing: 12) {
            KeyTimeSelectionView(store: store)
            MusicTimelineView(store: store)
            PlaybackControlBar(store: store)
        }
        .padding(.vertical)
        .background(Color.gray.opacity(0.1))
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
        .onAppear { store.send(.onAppear) }
    }
}

// MARK: - KeyTimeSelectionView

struct KeyTimeSelectionView: View {
    let store: StoreOf<TrimmerFeature>

    private var currentPct: Double {
        store.totalLength > 0 ? store.currentTime / store.totalLength : 0
    }

    var body: some View {
        VStack {
            VStack(spacing: 8) {
                Text("KeyTime Selection")
                    .font(.headline)

                Text("Selected: \(pct(store.selectionRange.lowerBound)) → \(pct(store.selectionRange.upperBound))")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text("Current: \(pct(currentPct))")
                    .font(.system(.body))
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }

            dotsTrack
                .padding(.vertical)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
        }
    }

    private var dotsTrack: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let rangeLength = store.selectionRange.upperBound - store.selectionRange.lowerBound

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 10)

                Capsule()
                    .fill(Color.yellow)
                    .frame(width: width * min(rangeLength, 1.0 - currentPct), height: 10)
                    .offset(x: width * currentPct)

                ForEach(store.keyTimes) { point in
                    Circle()
                        .fill(Color.pink)
                        .frame(width: 18, height: 18)
                        .offset(x: width * point.percentage - 9)
                        .onTapGesture { store.send(.keyTimeTapped(point.percentage)) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 28)
        .padding(.horizontal)
    }

    private func pct(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }
}

// MARK: - MusicTimelineView

struct MusicTimelineView: View {
    let store: StoreOf<TrimmerFeature>

    var body: some View {
        VStack {
            VStack(spacing: 8) {
                Text("Music Timeline")
                    .font(.headline)
                
                Text("Selected: \(formattedTime(store.selectionRange.lowerBound * store.totalLength)) → \(formattedTime(store.selectionRange.upperBound * store.totalLength))")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text("Current: \(formattedTime(store.currentTime))")
                    .font(.system(.body))
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }

            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 160)
                .overlay { Text("Music Timeline").foregroundStyle(.secondary) }
                .padding(.horizontal)
        }
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - PlaybackControlBar

struct PlaybackControlBar: View {
    let store: StoreOf<TrimmerFeature>

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {
                    store.send(.playButtonTapped)
                } label: {
                    Text(store.isPlaying ? "Pause" : "Play")
                        .frame(width: 88)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    store.send(.resetTapped)
                } label: {
                    Text("Reset")
                        .frame(width: 88)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.3))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    TrimmerView(
        store: Store(initialState: .mock) {
            TrimmerFeature()
        }
    )
}
