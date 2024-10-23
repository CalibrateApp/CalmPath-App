import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showDashboard = false
    @State var selectedOption: Int? = nil
    
    var body: some View {
        if authViewModel.isAuthenticated {
            if showDashboard {
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
                    
                    ProfileView(authViewModel: authViewModel)
                        .tabItem {

                            Image(systemName: "star")
                            Text("Top Rated")
                        }
                        .tag(3)

                }
                .environmentObject(authViewModel)
            } else {
                HomeView(showDashboard: $showDashboard)
            }
        } else {
            LoginView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
