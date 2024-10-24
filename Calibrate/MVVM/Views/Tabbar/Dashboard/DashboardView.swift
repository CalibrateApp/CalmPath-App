import SwiftUI
import Charts
import Firebase
import FirebaseFirestore
//import Calibrate // Add this line to import the module containing Habit


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
                        .foregroundStyle(.appBlue)
                        .frame(height: 213)
                        .ignoresSafeArea(edges: .top)
                        .overlay(
                            // Header
                            VStack {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Hi, \(authViewModel.user?.email.split(separator: "@").first ?? "there")!")
                                            .font(.Gilroy(weight: .bold, size: 24))
                                            .foregroundColor(.white)
                                        Text("How are you feeling today?")
                                            .font(.DMSans(weight: .regular, size: 14))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    .padding(.top, getTopSafeAreaInset())
                                    
                                    Spacer()
                                    HStack(alignment: .top ,spacing: 16) {
                                        Image(systemName: "bell")
                                            .foregroundColor(.white)
                                            .padding(.top, 6)
                                        Image(.profilePic)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 47, height: 47)
                                            .clipShape(Circle())
                                    }
                                }
                                .padding(.top, 36)
                                .padding(.horizontal)
                                Spacer()
                            }
                        )
                    
                    // Content
                    VStack(spacing: 12) {
                        // Daily Check-in Card
                        DailyCheckInCard(showingDailyCheckIn: $showingDailyCheckIn)
//                            .frame(width: min(geometry.size.width * 0.9, 400))
                        
                        // Habit Insights
                        HabitInsightsCard(habits: checkInViewModel.habits)
//                            .frame(width: min(geometry.size.width * 0.9, 400))
                        
                        // Anxiety Level Graph
                        if let errorMessage = checkInViewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        } else {
                            AnxietyLevelGraph(data: checkInViewModel.anxietyData)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 15)
                    .offset(y: -60)
//
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
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 14)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Monthly Anxiety Levels")
                    .font(.Gilroy(weight: .bold, size: 16))
                    .foregroundColor(Color.appBlack)
                    .padding(.top, 18)
                    .padding(.bottom, 8)

                
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
       
                    }
                    .foregroundColor(anxietyTrend.color)
                    
                    Text(anxietyDescription)
                        .font(.DMSans(weight: .regular, size: 14))
                        .foregroundColor(.appBlack)
                }
            }
            .padding(.bottom, 20)
            .padding(.horizontal, 15)
        }
        .padding(.bottom, 50)
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
    let buttonWidth: CGFloat = (UIScreen.main.bounds.width * 0.46)
    
    var body: some View {
        ZStack {
            
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 14)
            
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
                    .padding(.top, 6)
                
                Button(action: {
                    showingDailyCheckIn = true
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .frame(width: buttonWidth, height: 44)
                            .foregroundStyle(.appBlack)
                        Text("Check-In")
                            .font(.DMSans(weight: .bold, size: 14))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 34)
            }
        }
    }
}

struct HabitInsightsCard: View {
    let habits: [Habit]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 14)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Habit Insights")
                    .font(.custom("Gilroy-Bold", size: 16))
                    .foregroundColor(Color.appBlack)
                    .padding(.bottom, 11)
                    .padding(.top, 18)
                VStack(spacing: 12) {
                    ForEach(habits.prefix(4)) { habit in
                        HabitRow(icon: habit.icon ?? "❓", title: habit.name, progress: Double.random(in: 0...1), isPositive: habit.isPositive ?? true)
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 17)
        }
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
                .font(.DMSans(weight: .regular, size: 14))
                .foregroundColor(Color.black.opacity(0.65))
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

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(selectedTab: .constant(0))
            .environmentObject(AuthViewModel())
    }
}
