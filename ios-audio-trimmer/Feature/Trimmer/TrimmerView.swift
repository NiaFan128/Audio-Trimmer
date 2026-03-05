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

                Text("Selection: \(pct(store.selectionRange.lowerBound)) → \(pct(store.selectionRange.upperBound))")
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
                    .frame(width: width * rangeLength, height: 10)
                    .offset(x: width * store.selectionRange.lowerBound)

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

            TrimmerTimelineView(store: store)
                .padding(.horizontal)
        }
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - TrimmerTimelineView

struct TrimmerTimelineView: View {
    let store: StoreOf<TrimmerFeature>

    @GestureState private var dragStartLowerBound: Double? = nil

    private let selectionWindowRatio: CGFloat = 0.6

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let rangeWidth = CGFloat(store.selectionRange.upperBound - store.selectionRange.lowerBound)
            // Reverse-calculate contentWidth so the selection = selectionWindowRatio of screen
            let contentWidth = w * selectionWindowRatio / rangeWidth
            let selectionCenter = CGFloat(store.selectionRange.lowerBound + store.selectionRange.upperBound) / 2
            let waveformOffset = w / 2 - selectionCenter * contentWidth

            ZStack {
                Color.gray.opacity(0.2)

                // Waveform — uses .position() so ZStack frame is not affected by contentWidth
                Canvas { context, size in
                    guard let symbol = context.resolveSymbol(id: 0) else { return }
                    let step: CGFloat = 26
                    var x: CGFloat = step / 2
                    while x < size.width {
                        context.draw(symbol, at: CGPoint(x: x, y: size.height / 2))
                        x += step
                    }
                } symbols: {
                    Image(systemName: "waveform")
                        .font(.system(size: 30))
                        .foregroundStyle(.white.opacity(0.35))
                        .tag(0)
                }
                .frame(width: contentWidth, height: h)
                .position(x: waveformOffset + contentWidth / 2, y: h / 2)

                // Selection window — ZStack centers this at (w/2, h/2) ✓
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.08))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.orange, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                    }
                    .frame(width: w * selectionWindowRatio, height: h)
                    .allowsHitTesting(false)
            }
            .frame(width: w, height: h)  // Force ZStack = screen size, prevents waveform from expanding it
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragStartLowerBound) { _, state, _ in
                        if state == nil { state = store.selectionRange.lowerBound }
                    }
                    .onChanged { value in
                        guard let start = dragStartLowerBound else { return }
                        // Drag right → selection moves left
                        let delta = -value.translation.width / contentWidth
                        store.send(.selectionWindowMoved(to: start + delta))
                    }
            )
        }
        .frame(height: 80)
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
