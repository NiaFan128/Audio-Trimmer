//
//  ios_audio_trimmerApp.swift
//  ios-audio-trimmer
//
//  Created by Nia Fan on 2026/2/28.
//

import ComposableArchitecture
import SwiftUI

@main
struct ios_audio_trimmerApp: App {
    var body: some Scene {
        WindowGroup {
            SettingsView(
                store: Store(initialState: SettingsFeature.State()) {
                    SettingsFeature()
                }
            )
        }
    }
}
