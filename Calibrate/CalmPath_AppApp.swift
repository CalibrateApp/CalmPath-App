import SwiftUI
import Firebase

@main
struct CalmPath_AppApp: App {
    @StateObject var authViewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .onAppear {
                    for family in UIFont.familyNames {
                        for font in UIFont.fontNames(forFamilyName: family) {
                            print("Font: \(font)")
                        }
                    }
                }
        }
    }
}
