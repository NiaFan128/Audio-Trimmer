//
//  Double+Rounded.swift
//  AudioTrimmer
//
//  Created by Nia Fan on 2026/3/6.
//

import Foundation

extension Double {
    func rounded(places: Int = 4) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded(.toNearestOrAwayFromZero) / factor
    }
}
