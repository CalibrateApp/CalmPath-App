import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        if authViewModel.isAuthenticated {
            TabView(selection: $selectedTab) {
                DashboardView(selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "house")
                        Text("Dashboard")
                    }
                    .tag(0)
                
                TopRatedView(selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "star")
                        Text("Top Rated")
                    }
                    .tag(1)
                
                LearningView()
                    .tabItem {
                        Image(systemName: "book")
                        Text("Learning")
                    }
                    .tag(2)
                
                ProfileView(authViewModel: authViewModel)
                    .tabItem {
                        Image(systemName: "person")
                        Text("Profile")
                    }
                    .tag(3)
            }
        } else {
            LoginView()
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AuthViewModel())
    }
}
