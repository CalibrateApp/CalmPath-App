import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Calibrate")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)))
                .padding(.top, 50)
           
            VStack(alignment: .center, spacing: 10) {
                Text("Login to your account")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Welcome back to Calibrate!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 30)
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.gray)
                    TextField("Email", text: $email)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.gray)
                    SecureField("Password", text: $password)
                    Button(action: {
                        // Toggle password visibility
                    }) {
                        Image(systemName: "eye.slash")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            HStack {
                Toggle("Remember me", isOn: $rememberMe)
                    .toggleStyle(CheckboxToggleStyle())
                Spacer()
                Button("Forgot password?") {
                    // Handle forgot password
                }
                .foregroundColor(Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)))
            }
            .font(.subheadline)
            
            Button(action: {
                authViewModel.userData.email = email
                authViewModel.userData.password = password
                authViewModel.signIn()
            }) {
                Text("Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Text("or")
                .foregroundColor(.gray)
            
            HStack(spacing: 20) {
                SocialLoginButton(image: "Google")
                SocialLoginButton(image: "Apple")
                SocialLoginButton(image: "Facebook")
            }
            
            Spacer()
            
            HStack {
                Text("No account yet?")
                Button("Sign up") {
                    // Handle sign up
                }
                .foregroundColor(Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)))
            }
            .font(.subheadline)
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)) : .gray)
                .onTapGesture { configuration.isOn.toggle() }
            configuration.label
        }
    }
}

struct SocialLoginButton: View {
    let image: String
    
    var body: some View {
        Button(action: {
            // Handle social login
        }) {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
