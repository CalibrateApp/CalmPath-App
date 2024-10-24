//
//  struct.swift
//  Calibrate
//
//  Created by Hadi on 24/10/2024.
//

import Foundation


// Update the AnxietyDataPoint struct
struct AnxietyDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let level: Double?  // This will now represent a percentage (0-100)
}
