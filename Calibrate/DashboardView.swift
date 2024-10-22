import SwiftUI
import Charts
import Firebase
import FirebaseFirestore
//import Calibrate // Add this line to import the module containing Habit

// Update the AnxietyDataPoint struct
struct AnxietyDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let level: Double?  // This will now represent a percentage (0-100)
}

struct CheckIn: Codable, Identifiable {
    let id: String
    let userId: String
    let date: Date
    let anxietyLevel: Double
    let selectedHabits: [String]
    let notes: String
}

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

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var checkInViewModel = CheckInViewModel()
    @Binding var selectedTab: Int
    @State private var showingDailyCheckIn = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Blue background
                    Rectangle()
                        .fill(Color(red: 0.23, green: 0.62, blue: 0.90))
                        .frame(height: 213)
                        .ignoresSafeArea(edges: .top)
                        .overlay(
                            // Header
                            VStack {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Hi, \(authViewModel.user?.email.split(separator: "@").first ?? "there")!")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Text("How are you feeling today?")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    Spacer()
                                    HStack {
                                        Image(systemName: "bell")
                                            .foregroundColor(.white)
                                        Image("profile_pic")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, getTopSafeAreaInset())
                                Spacer()
                            }
                        )
                    
                    // Content
                    VStack(spacing: 20) {
                        // Daily Check-in Card
                        DailyCheckInCard(showingDailyCheckIn: $showingDailyCheckIn)
                            .frame(width: min(geometry.size.width * 0.9, 400))
                            .offset(y: -85)
                        
                        // Habit Insights
                        HabitInsightsCard(habits: checkInViewModel.habits)
                            .frame(width: min(geometry.size.width * 0.9, 400))
                            .offset(y: -65)
                        
                        // Anxiety Level Graph
                        if let errorMessage = checkInViewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        } else {
                            AnxietyLevelGraph(data: checkInViewModel.anxietyData)
                                .frame(width: min(geometry.size.width * 0.9, 400))
                                .offset(y: -45)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .edgesIgnoringSafeArea(.top)
        }
        .sheet(isPresented: $showingDailyCheckIn) {
            DailyCheckInView(checkInViewModel: checkInViewModel)
        }
        .onAppear {
            if let userId = authViewModel.user?.id {
                checkInViewModel.setUserId(userId)
                checkInViewModel.fetchCheckIns(for: userId)
                checkInViewModel.fetchHabits()
            }
        }
    }
    
    // Helper function to get the top safe area inset
    private func getTopSafeAreaInset() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first
        else {
            return 0
        }
        return window.safeAreaInsets.top
    }
}

// Update the AnxietyLevelGraph struct
struct AnxietyLevelGraph: View {
    let data: [AnxietyDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Anxiety Levels")
                .font(.headline)
            
            if data.isEmpty {
                Text("No check-in data available. Start logging your anxiety levels to see trends.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Chart {
                    ForEach(data) { dataPoint in
                        if let level = dataPoint.level {
                            LineMark(
                                x: .value("Day", dataPoint.date, unit: .day),
                                y: .value("Level", level)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.catmullRom)
                            
                            AreaMark(
                                x: .value("Day", dataPoint.date, unit: .day),
                                y: .value("Level", level)
                            )
                            .foregroundStyle(.linearGradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)%")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            let calendar = Calendar.current
                            if calendar.component(.day, from: date) == 1 || calendar.component(.day, from: date) % 5 == 0 {
                                AxisValueLabel(format: .dateTime.day())
                            }
                        }
                    }
                }
                
                HStack {
                    Image(systemName: anxietyTrend.icon)
                    Text(anxietyTrend.text)
                        .font(.headline)
                }
                .foregroundColor(anxietyTrend.color)
                
                Text(anxietyDescription)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(width: 345, height: 300)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.03), radius: 30, x: 10, y: 10)
    }
    
    var anxietyTrend: (text: String, icon: String, color: Color) {
        let validData = data.compactMap { $0.level }
        guard validData.count >= 2 else {
            return ("Keep logging to see trends", "exclamationmark.circle", .gray)
        }
        let lastValue = validData.last!
        let previousValue = validData[validData.count - 2]
        let difference = lastValue - previousValue
        let percentageChange = abs(difference)
        
        if difference < 0 {
            return ("Anxiety down \(String(format: "%.1f", percentageChange))% from yesterday", "arrow.down.circle.fill", .green)
        } else if difference > 0 {
            return ("Anxiety up \(String(format: "%.1f", percentageChange))% from yesterday", "arrow.up.circle.fill", .red)
        } else {
            return ("Anxiety unchanged from yesterday", "equal.circle.fill", .blue)
        }
    }
    
    var anxietyDescription: String {
        let validData = data.compactMap { $0.level }
        guard validData.count >= 2 else {
            return "Log more check-ins to see detailed trends."
        }
        let firstValue = validData.first!
        let lastValue = validData.last!
        let difference = lastValue - firstValue
        let trend = difference < 0 ? "decreased" : "increased"
        return String(format: "Overall, your anxiety has %@ by %.1f percentage points since your first check-in. %@",
                      trend, abs(difference), difference < 0 ? "You're on the right path!" : "Let's work on reducing it.")
    }
}

struct DailyCheckInCard: View {
    @Binding var showingDailyCheckIn: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Image("Laying Down")
                .resizable()
                .scaledToFit()
                .frame(height: 149)
            
            Text("Take 5mn to Check-In")
                .font(.custom("Gilroy-Bold", size: 16))
                .foregroundColor(Color(red: 0.02, green: 0.02, blue: 0.08))
            
            Text("Check-in and update your daily diary.")
                .font(.custom("DM Sans", size: 14))
                .foregroundColor(Color(red: 0.28, green: 0.28, blue: 0.28).opacity(0.60))
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingDailyCheckIn = true
            }) {
                Text("Check-In")
                    .font(.custom("DM Sans", size: 14).weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(red: 0.02, green: 0.02, blue: 0.08))
                    .cornerRadius(100)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.03), radius: 30, x: 10, y: 10)
    }
}

struct HabitInsightsCard: View {
    let habits: [Habit]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Habit Insights")
                .font(.custom("Gilroy-Bold", size: 16))
                .foregroundColor(Color(red: 0.02, green: 0.02, blue: 0.08))
                .padding(.bottom, 5)
            
            ForEach(habits.prefix(4)) { habit in
                HabitRow(icon: habit.icon ?? "❓", title: habit.name ?? "Unnamed Habit", progress: Double.random(in: 0...1), isPositive: habit.isPositive ?? true)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.03), radius: 30, x: 10, y: 10)
    }
}

struct HabitRow: View {
    let icon: String
    let title: String
    let progress: Double
    let isPositive: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Text("\(icon) \(title)")
                .font(.custom("DM Sans", size: 14))
                .foregroundColor(Color(red: 0, green: 0, blue: 0).opacity(0.65))
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            CenteredProgressBar(progress: progress, isPositive: isPositive)
                .frame(width: 160)
        }
        .frame(height: 27)
    }
}

struct CenteredProgressBar: View {
    let progress: Double
    let isPositive: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // Background
                Rectangle()
                    .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .frame(width: geometry.size.width, height: 27)
                    .cornerRadius(100)
                
                // Progress bar
                Rectangle()
                    .foregroundColor(isPositive ? Color(red: 0.23, green: 0.62, blue: 0.90) : Color(red: 0.93, green: 0.23, blue: 0.27))
                    .frame(width: CGFloat(progress) * geometry.size.width / 2, height: 27)
                    .cornerRadius(100)
                    .offset(x: isPositive ? CGFloat(progress) * geometry.size.width / 4 : -CGFloat(progress) * geometry.size.width / 4)
                
                // Center line
                Rectangle()
                    .foregroundColor(.gray)
                    .frame(width: 1, height: 27)
            }
        }
        .frame(height: 27)
    }
}
//
//struct DashboardView_Previews: PreviewProvider {
//    static var previews: some View {
//        DashboardView(selectedTab: .constant(0))
//            .environmentObject(AuthViewModel())
//    }
//}
