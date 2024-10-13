import SwiftUI

struct BottomNavigation: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            NavButton(icon: "house", title: "Home", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            NavButton(icon: "star", title: "Top Rated", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            NavButton(icon: "book", title: "Learning", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            NavButton(icon: "person", title: "Profile", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
        }
        .padding(.vertical, 8)
        .padding(.bottom, 20) // Add padding to move it up from the bottom
        .background(Color.white)
        .shadow(radius: 5)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct NavButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .blue : .gray)
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
