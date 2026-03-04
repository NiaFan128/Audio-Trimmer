//
//  ContentView.swift
//  ios-audio-trimmer
//
//  Created by Nia Fan on 2026/2/28.
//

import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    var body: some View {
        SettingsView(
            store: Store(initialState: SettingsFeature.State()) {
                SettingsFeature()
            }
        )
    }
}

#Preview {
    ContentView()
}
