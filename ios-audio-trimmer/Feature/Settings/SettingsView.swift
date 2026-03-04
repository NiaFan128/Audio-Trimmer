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
        } footer: {
            Text("Type 4 digits — colon is added automatically (e.g. 0230 → 02:30)")
                .font(.caption)
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
        Section {
            ForEach(store.keyTimes) { point in
                KeyTimeRow(point: point)
            }
        } header: {
            HStack {
                Text("Key Times")
                Spacer()
                Button {
                    store.send(.addKeyTimePointTapped)
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
    }

    var editAudioSection: some View {
        Section {
            Button {
                store.send(.editAudioTapped)
            } label: {
                Text("Edit Audio")
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - KeyTimeRow

private struct KeyTimeRow: View {
    let point: KeyTimePoint

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.pink)
                .frame(width: 8, height: 8)
            Text(String(format: "%.1f%%", point.percentage * 100))
                .monospacedDigit()
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
