//
//  SettingsView.swift
//  ios-audio-trimmer
//
//  Created by Nia Fan on 2026/3/4.
//

import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @FocusState private var isLengthFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                trackLengthSection
                keyTimesSection
                editAudioSection
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Settings")
            .navigationDestination(
                item: $store.scope(state: \.trimmer, action: \.trimmer)
            ) { trimmerStore in
                TrimmerView(store: trimmerStore)
                    .navigationTitle("Audio Trimmer")
            }
        }
    }
}

// MARK: - Sections

private extension SettingsView {

    var trackLengthSection: some View {
        Section {
            TextField("0230", text: $store.totalLengthText)
                .keyboardType(.numberPad)
                .monospacedDigit()
                .focused($isLengthFocused)
                .onChange(of: store.totalLengthText) { _, newValue in
                    let formatted = Self.formatMMSS(newValue)
                    if formatted != newValue {
                        store.totalLengthText = formatted
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { isLengthFocused = false }
                    }
                }
        } header: {
            Text("Track Length")
        }
    }

    static func formatMMSS(_ input: String) -> String {
        let digits = String(input.filter(\.isNumber).prefix(4))
        guard digits.count >= 3 else { return digits }
        let mm = String(digits.prefix(2))
        let ss = String(digits.dropFirst(2))
        return "\(mm):\(ss)"
    }

    var keyTimesSection: some View {
        Section("Key Times") {
            ForEach(store.keyTimes) { point in
                KeyTimeRow(point: point, totalLengthText: store.totalLengthText)
            }
            .onDelete { store.send(.deleteKeyTime($0)) }

            Button {
                store.send(.addKeyTimePointTapped)
            } label: {
                Label("Add Key Time", systemImage: "plus")
            }
        }
    }

    var editAudioSection: some View {
        Section {
            Button {
                store.send(.editAudioTapped)
            } label: {
                Text("Start Trimming")
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - KeyTimeRow

private struct KeyTimeRow: View {
    let point: KeyTimePoint
    let totalLengthText: String

    private var timeString: String {
        let parts = totalLengthText.split(separator: ":")
        guard parts.count == 2,
              let mm = Double(parts[0]),
              let ss = Double(parts[1])
        else { return "--:--" }
        let total = mm * 60 + ss
        let t = point.percentage * total
        return String(format: "%02d:%02d", Int(t) / 60, Int(t) % 60)
    }

    var body: some View {
        HStack {
            Circle()
                .fill(Color.pink)
                .frame(width: 8, height: 8)
            Text(String(format: "%.0f%%", point.percentage * 100))
                .monospacedDigit()
            Spacer()
            Text(timeString)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
}
