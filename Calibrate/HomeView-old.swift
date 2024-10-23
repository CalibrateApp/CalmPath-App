import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showDashboard: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to CalmPath")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Thank you for downloading our app!")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Text("CalmPath is here to help you manage anxiety and find peace in your daily life.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                showDashboard = true
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(minWidth: 200)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(showDashboard: .constant(false))
            .environmentObject(AuthViewModel())
    }
}
