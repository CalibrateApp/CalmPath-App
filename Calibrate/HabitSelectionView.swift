import SwiftUI

struct HabitSelectionView: View {
    @ObservedObject var checkInViewModel: CheckInViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(checkInViewModel.habits) { habit in
                    HabitSelectionRow(habit: habit, isSelected: checkInViewModel.selectedHabitIds.contains(habit.id)) {
                        checkInViewModel.toggleHabitSelection(habit.id)
                    }
                }
            }
            .navigationBarTitle("Select Habits", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct HabitSelectionRow: View {
    let habit: Habit
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(habit.name)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}