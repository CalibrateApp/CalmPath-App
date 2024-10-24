//
//  CheckIn.swift
//  Calibrate
//
//  Created by Hadi on 24/10/2024.
//

import Foundation

struct CheckIn: Codable, Identifiable {
    let id: String
    let userId: String
    let date: Date
    let anxietyLevel: Double
    let selectedHabits: [String]
    let notes: String
}
