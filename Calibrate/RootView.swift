import SwiftUI

struct RootView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var selectedTab = 0
    
    @State var selectedOption: Int? = nil

    var body: some View {
        if authViewModel.isAuthenticated {
            
            GeometryReader { reader in
                
                ZStack(alignment: .bottom) {
                    
                    TabView(selection: $selectedTab) {
                        DashboardView(selectedTab: $selectedTab)
                            .toolbar(.hidden, for: .tabBar)
                            .tag(0)
                        
                        TopRatedView(selectedTab: $selectedTab)
                            .toolbar(.hidden, for: .tabBar)
                            .tag(1)
                        
                        LearningView()
                            .toolbar(.hidden, for: .tabBar)
                            .tag(2)
                        
                        ProfileView(authViewModel: authViewModel)
                            .toolbar(.hidden, for: .tabBar)
                            .tag(3)
                    }
                    
                    CustomTabBar(selectedTab: $selectedTab, height: 65 + reader.safeAreaInsets.bottom)
                }
                .ignoresSafeArea()
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
