//
//  KeyTimePoint.swift
//  ios-audio-trimmer
//
//  Created by Nia Fan on 2026/3/4.
//

import Foundation

struct KeyTimePoint: Equatable, Identifiable, Sendable {
    let id: UUID
    var percentage: Double
}
