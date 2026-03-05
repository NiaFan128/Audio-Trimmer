//
//  AudioTrimmerApp.swift
//  ios-audio-trimmer
//
//  Created by Nia Fan on 2026/2/28.
//

import ComposableArchitecture
import SwiftUI

@main
struct AudioTrimmerApp: App {
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
