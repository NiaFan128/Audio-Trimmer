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
            Spacer()
            ControlBar(store: store)
        }
        .padding(.vertical)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
        .onAppear { store.send(.onAppear) }
    }
}

// MARK: - KeyTimeSelectionView

struct KeyTimeSelectionView: View {
    let store: StoreOf<TrimmerFeature>

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.2))
            .frame(height: 120)
            .overlay { Text("KeyTime Selection").foregroundStyle(.secondary) }
            .padding(.horizontal)
    }
}

// MARK: - MusicTimelineView

struct MusicTimelineView: View {
    let store: StoreOf<TrimmerFeature>

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.2))
            .frame(height: 160)
            .overlay { Text("Music Timeline").foregroundStyle(.secondary) }
            .padding(.horizontal)
    }
}

// MARK: - ControlBar

struct ControlBar: View {
    let store: StoreOf<TrimmerFeature>

    var body: some View {
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
                
            } label: {
                Text("Reset")
                    .frame(width: 88)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.3))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
