import SwiftUI

struct UserAuthenticationView: View {
    @State private var showingLogin = true

    var body: some View {
        ZStack {
            Color.calmBlue
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Logo and App Name
                VStack {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .padding()
                    
                    Text("Calm Path")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.bottom, 50)
                
                // Authentication Views
                if showingLogin {
                    LoginView()
                } else {
                    SignUpView()
                }
                
                // Toggle between Login and Sign Up
                Button(action: {
                    showingLogin.toggle()
                }) {
                    Text(showingLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In")
                        .foregroundColor(.blue)
                }
                .padding()
            }
        }
    }
}

struct UserAuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        UserAuthenticationView()
            .environmentObject(AuthViewModel())
    }
}
