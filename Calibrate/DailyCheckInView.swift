import SwiftUI

struct DailyCheckInView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var checkInViewModel: CheckInViewModel
    @State private var anxietyLevel: Double = 0.5
    @State private var selectedHabits: Set<String> = []
    @State private var notes: String = ""
    @State private var showingHabitSelection = false
    @State var selectedOption:Int? = nil
    @State var wentGym: Bool = false
    @State var followedDiet: Bool = false
    @State var didMeditation: Bool = false
    @State var hadColdShower: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
            VStack(alignment: .leading) {
                Text("Take 5mn to complete your daily check-in")
                    .font(.DMSans(weight: .regular, size: 14))
                    .padding(.top, 7)
                    .padding(.bottom, 22)
                
                Text("What did you consume yesterday?")
                    .foregroundStyle(.black)
                    .font(.Gilroy(weight: .bold, size: 15))
                    .padding(.bottom, 8)
                
                ScrollView(.horizontal) {
                    HStack(spacing: 9) {
                        optionButton(emoji: "☕", title: "Caffiene", isSelected: selectedOption == 0) {
                            selectedOption = 0
                        }
                        optionButton(emoji: "🥃", title: "Alcohol", isSelected: selectedOption == 1) {
                            selectedOption = 1
                        }
                        optionButton(emoji: "💊", title: "Medication", isSelected: selectedOption == 2) {
                            selectedOption = 2
                        }
                    }
                }
                .padding(.bottom, 39)
                
                Text("What happened yesterday?")
                    .font(.Gilroy(weight: .bold, size: 15))
                    .padding(.bottom, 10)
                
                VStack(spacing: 18) {
                    
                    wentGym(text: "Went to the gym")
                    
                    followedDiet(text: "Followed an intermittent fasting diet")
                    
                    didMeditation(text: "Did a meditation session")
                    
                    hadColdShower(text: "Had a cold shower")
                    
                }
                
                Text("Anxiety Levels")
                    .font(.Gilroy(weight: .bold, size: 15))
                    .padding(.top, 39)
                    .padding(.bottom, 27)
                
                Slider(value: $anxietyLevel, in: 0...1, step: 0.01)
                    .tint(.appBlue)
                
                Text("Moderately Anxious")
                    .foregroundStyle(.appGray3)
                    .font(.DMSans(weight: .medium, size: 13))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 39)
                
                Text("Anything you'd like to share?")
                    .font(.Gilroy(weight: .bold, size: 15))
                    .padding(.bottom, 8)
                
                ForEach(checkInViewModel.habits.filter { checkInViewModel.selectedHabitIds.contains($0.id) }) { habit in
                    HabitToggleRow(habit: habit, isSelected: selectedHabits.contains(habit.id)) { isSelected in
                        if isSelected {
                            selectedHabits.insert(habit.id)
                        } else {
                            selectedHabits.remove(habit.id)
                        }
                    }
                }
                
                ZStack {
                    
                    
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray)
                        .frame(height: 88)
                    
                    HStack(alignment: .top ,spacing: 9) {
                        Image(.message)
                        
                        Text("What's on your mind?")
                            .font(.DMSans(weight: .regular, size: 14))
                    }
                    .padding(.leading, 18)
                    .padding(.bottom, 50)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextEditor(text: $notes)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(height: 88)
                        .opacity(0.5)
                    
                }
                Button(action: saveCheckIn) {
                    Text("Submit")
                        .font(.DMSans(weight: .bold, size: 14))
                        .foregroundColor(.appWhite2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appBlue)
                        .cornerRadius(10)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 15)

        }
            .navigationBarItems(leading: Text("Check-In").font(.Gilroy(weight: .bold, size:22)))
            
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(.arrowLeft)
            }))
            

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
    @ViewBuilder
    func wentGym(text: String) -> some View {
        Toggle(isOn: $wentGym) {
            Text(text)
                .font(.DMSans(weight: .medium, size: 14))
        }
        .toggleStyle(SwitchToggleStyle(tint: .appBlue))
    }
    @ViewBuilder
    func followedDiet(text: String) -> some View {
        Toggle(isOn: $followedDiet) {
            Text(text)
                .font(.DMSans(weight: .medium, size: 14))
        }
        .toggleStyle(SwitchToggleStyle(tint: .appBlue))
    }

    @ViewBuilder
    func didMeditation(text: String) -> some View {
        Toggle(isOn: $didMeditation) {
            Text(text)
                .font(.DMSans(weight: .medium, size: 14))
        }
        .toggleStyle(SwitchToggleStyle(tint: .appBlue))
    }

    @ViewBuilder
    func hadColdShower(text: String) -> some View {
        Toggle(isOn: $hadColdShower) {
            Text(text)
                .font(.DMSans(weight: .medium, size: 14))
        }
        .toggleStyle(SwitchToggleStyle(tint: .appBlue))
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

struct optionButton: View {
    let emoji: String
    let title: String
    var isSelected: Bool
//    let buttonWidth: CGFloat = (UIScreen.main.bounds.width - 58) / 3
    var action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Text(emoji)

                Text(title)
                    .foregroundStyle(isSelected ? Color.appWhite2 : Color.black)
                    .font(.DMSans(weight: .medium, size: 13))

            }
            .padding(.vertical, 10)
            .padding(.horizontal, 17)
            .background {
                RoundedRectangle(cornerRadius: 100)
                    .foregroundStyle(isSelected ? Color.appBlue : Color.appWhite)
//                    .frame(height: 37)
            }
        }
    }

}


struct DailyCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        DailyCheckInView(checkInViewModel: CheckInViewModel())
            .environmentObject(AuthViewModel())
    }
}
