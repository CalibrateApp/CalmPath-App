//
//  CheckInViewModel.swift
//  Calibrate
//
//  Created by Hadi on 24/10/2024.
//

import Foundation
import Firebase

class CheckInViewModel: ObservableObject {
    @Published var anxietyData: [AnxietyDataPoint] = []
    @Published var habits: [Habit] = []
    @Published var selectedHabitIds: Set<String> = []
    @Published var errorMessage: String?
    @Published var todayCheckIn: CheckIn?
    private var db = Firestore.firestore()
    private var userId: String?
    
    init() {
        fetchHabits()
    }
    
    func setUserId(_ id: String) {
        self.userId = id
        loadSelectedHabits()
        checkForTodayCheckIn()
    }
    
    func toggleHabitSelection(_ habitId: String) {
        if selectedHabitIds.contains(habitId) {
            selectedHabitIds.remove(habitId)
        } else {
            selectedHabitIds.insert(habitId)
        }
        saveSelectedHabits()
    }
    
    private func saveSelectedHabits() {
        guard let userId = userId else { return }
        db.collection("users").document(userId).setData(["selectedHabits": Array(selectedHabitIds)], merge: true) { error in
            if let error = error {
                print("Error saving selected habits: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadSelectedHabits() {
        guard let userId = userId else { return }
        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, document.exists {
                if let selectedHabits = document.data()?["selectedHabits"] as? [String] {
                    self.selectedHabitIds = Set(selectedHabits)
                }
            } else {
                print("User document does not exist")
            }
        }
    }
    
    private func checkForTodayCheckIn() {
        guard let userId = userId else { return }
        let today = Calendar.current.startOfDay(for: Date())
        db.collection("checkIns")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: today)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting today's check-in: \(error.localizedDescription)")
                    return
                }
                
                if let document = querySnapshot?.documents.first {
                    self.todayCheckIn = try? document.data(as: CheckIn.self)
                }
            }
    }
    
    func saveOrUpdateCheckIn(anxietyLevel: Double, selectedHabits: [String], notes: String) {
        guard let userId = userId else { return }
        let today = Calendar.current.startOfDay(for: Date())
        
        let checkIn = CheckIn(id: todayCheckIn?.id ?? UUID().uuidString,
                              userId: userId,
                              date: today,
                              anxietyLevel: anxietyLevel,
                              selectedHabits: selectedHabits,
                              notes: notes)
        
        if todayCheckIn != nil {
            // Update existing check-in
            do {
                try db.collection("checkIns").document(checkIn.id).setData(from: checkIn)
                self.todayCheckIn = checkIn
                print("Check-in updated successfully")
            } catch {
                print("Error updating check-in: \(error.localizedDescription)")
                self.errorMessage = "Failed to update check-in. Please try again."
            }
        } else {
            // Create new check-in
            do {
                try db.collection("checkIns").document(checkIn.id).setData(from: checkIn)
                self.todayCheckIn = checkIn
                print("Check-in saved successfully")
            } catch {
                print("Error saving check-in: \(error.localizedDescription)")
                self.errorMessage = "Failed to save check-in. Please try again."
            }
        }
        
        fetchCheckIns(for: userId)
    }
    
    func fetchHabits() {
        print("Fetching habits...")
        db.collection("habits").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting habits: \(error.localizedDescription)")
                self.errorMessage = "Failed to fetch habits. Please try again later."
                return
            }
            
            print("Received \(querySnapshot?.documents.count ?? 0) habit documents")
            
            self.habits = querySnapshot?.documents.compactMap { document -> Habit? in
                let data = document.data()
                let id = document.documentID
                let name = data["name"] as? String ?? "Unnamed Habit"
                let icon = data["icon"] as? String
                let isPositive = data["isPositive"] as? Bool
                
                let habit = Habit(id: id, name: name, icon: icon, isPositive: isPositive)
                print("Parsed habit: \(habit)")
                return habit
            } ?? []
            
            print("Parsed \(self.habits.count) habits")
            
            // Force UI update
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            
            // After fetching habits, load selected habits
            self.loadSelectedHabits()
        }
    }
    
    func fetchCheckIns(for userId: String) {
        print("Fetching check-ins for user: \(userId)")
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        db.collection("checkIns")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThan: thirtyDaysAgo)
            .order(by: "date", descending: false)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error.localizedDescription)")
                    self.errorMessage = "Failed to fetch check-ins. Please try again later."
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    self.errorMessage = "No check-in data available."
                    return
                }
                
                print("Number of documents fetched: \(documents.count)")
                
                self.anxietyData = documents.compactMap { document -> AnxietyDataPoint? in
                    guard let date = (document.get("date") as? Timestamp)?.dateValue(),
                          let anxietyLevel = document.get("anxietyLevel") as? Double else {
                        print("Failed to parse document: \(document.data())")
                        return nil
                    }
                    // Convert the anxiety level to a percentage
                    let anxietyPercentage = anxietyLevel * 100
                    return AnxietyDataPoint(date: date, level: anxietyPercentage)
                }
                
                print("Parsed anxiety data points: \(self.anxietyData.count)")
                
                // If there are less than 30 data points, pad with nil values
                if !self.anxietyData.isEmpty {
                    self.padAnxietyData()
                }
                
                self.errorMessage = nil
                
                // Force UI update
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
    }
    
    private func padAnxietyData() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd"
        
        var paddedData: [AnxietyDataPoint] = []
        let startDate = self.anxietyData.first?.date ?? Date()
        for i in 0..<30 {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: startDate) {
                if let existingDataPoint = self.anxietyData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                    paddedData.append(existingDataPoint)
                } else {
                    paddedData.append(AnxietyDataPoint(date: date, level: nil))
                }
            }
        }
        
        self.anxietyData = paddedData
        print("Total data points after padding: \(self.anxietyData.count)")
    }
}
