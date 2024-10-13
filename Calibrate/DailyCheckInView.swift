import SwiftUI

struct DailyCheckInView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var checkInViewModel: CheckInViewModel
    @State private var anxietyLevel: Double = 0.5
    @State private var selectedHabits: Set<String> = []
    @State private var notes: String = ""
    @State private var showingHabitSelection = false
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("How are you feeling?")) {
                        Slider(value: $anxietyLevel, in: 0...1, step: 0.01)
                        Text("Anxiety Level: \(Int(anxietyLevel * 100))%")
                    }
                    
                    Section(header: HStack {
                        Text("What happened yesterday?")
                        Spacer()
                        Button(action: { showingHabitSelection = true }) {
                            Image(systemName: "gear")
                        }
                    }) {
                        ForEach(checkInViewModel.habits.filter { checkInViewModel.selectedHabitIds.contains($0.id) }) { habit in
                            HabitToggleRow(habit: habit, isSelected: selectedHabits.contains(habit.id)) { isSelected in
                                if isSelected {
                                    selectedHabits.insert(habit.id)
                                } else {
                                    selectedHabits.remove(habit.id)
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Notes")) {
                        TextEditor(text: $notes)
                            .frame(height: 100)
                    }
                }
                
                Button(action: saveCheckIn) {
                    Text(checkInViewModel.todayCheckIn == nil ? "Save Check-In" : "Update Check-In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationBarTitle("Daily Check-In", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingHabitSelection) {
                HabitSelectionView(checkInViewModel: checkInViewModel)
            }
            .onAppear {
                if let todayCheckIn = checkInViewModel.todayCheckIn {
                    anxietyLevel = todayCheckIn.anxietyLevel
                    selectedHabits = Set(todayCheckIn.selectedHabits)
                    notes = todayCheckIn.notes
                } else {
                    selectedHabits = checkInViewModel.selectedHabitIds
                }
            }
        }
    }
    
    private func saveCheckIn() {
        checkInViewModel.saveOrUpdateCheckIn(
            anxietyLevel: anxietyLevel,
            selectedHabits: Array(selectedHabits),
            notes: notes
        )
        presentationMode.wrappedValue.dismiss()
    }
}

struct HabitToggleRow: View {
    let habit: Habit
    let isSelected: Bool
    let action: (Bool) -> Void
    
    var body: some View {
        HStack {
            Text(habit.name)
                .font(.body)
            Spacer()
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { action($0) }
            ))
            .labelsHidden()
        }
    }
}

struct DailyCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        DailyCheckInView(checkInViewModel: CheckInViewModel())
            .environmentObject(AuthViewModel())
    }
}