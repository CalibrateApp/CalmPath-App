import SwiftUI

//struct BottomNavigation: View {
//     var selectedTab: Bool
//
//    var body: some View {
//        HStack(spacing: 0) {
//            NavButton(icon: "house", title: "Home", isSelected: selectedTab == 0) {
//                selectedTab = 0
//            }
//            NavButton(icon: "star", title: "Top Rated", isSelected: selectedTab == 1) {
//                selectedTab = 1
//            }
//            NavButton(icon: "book", title: "Learning", isSelected: selectedTab == 2) {
//                selectedTab = 2
//            }
//            NavButton(icon: "person", title: "Profile", isSelected: selectedTab == 3) {
//                selectedTab = 3
//            }
//        }
//        .padding(.vertical, 8)
//        .padding(.bottom, 20) // Add padding to move it up from the bottom
//        .background(Color.white)
//        .shadow(radius: 5)
//        .edgesIgnoringSafeArea(.bottom)
//    }
//}

struct NavButton: View {
    let icon: String
    var isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .tint(isSelected ? .black : .blue)
                Circle()
                    .fill(isSelected ? .black : .clear)
                    .frame(width: 4, height: 4)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
