import SwiftUI
import FirebaseAuth // Change this line from 'import Firebase'

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var isEditing = false
    @State private var userName: String = ""
    @State private var userBio: String = ""
    @State private var userImage: UIImage?
    @State private var showImagePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                profileHeader
                
                // Stats
                HStack(spacing: 15) {
                    StatCard(title: "Check-Ins", value: "\(authViewModel.user?.checkInCount ?? 0)", iconName: "checkins")
                    StatCard(title: "Habits", value: "4", iconName: "alcohol")
                    StatCard(title: "Anxiety Lvl", value: "\(authViewModel.user?.currentStreak ?? 0)", iconName: "anxietylvl")
                }
                .padding(.horizontal)
                
                // Achievements
                achievementsSection
                
                // Recent Check-Ins
                recentCheckInsSection
                
                habitsSection
                
                // Sign Out Button
                Button(action: {
                    authViewModel.signOut()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
            .padding(.bottom, 80)
            .padding(.horizontal)
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $userImage)
        }
        .onAppear {
            print("ProfileView appeared. Current user ID: \(Auth.auth().currentUser?.uid ?? "No user ID")")
            print("AuthViewModel user before refresh: \(String(describing: authViewModel.user))")
            authViewModel.refreshCurrentUserProfile()
        }
    }
    
    private var profileHeader: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    if isEditing {
                        print("Save button pressed. Name: \(userName), Bio: \(userBio)")
                        if authViewModel.user != nil {
                            authViewModel.updateUserProfile(name: userName, bio: userBio)
                            if let image = userImage {
                                authViewModel.uploadProfileImage(image) { result in
                                    switch result {
                                    case .success(let url):
                                        authViewModel.updateProfileImageURL(url)
                                    case .failure(let error):
                                        print("Failed to upload image: \(error.localizedDescription)")
                                    }
                                }
                            }
                        } else {
                            print("Cannot update profile: User is nil")
                        }
                    }
                    isEditing.toggle()
                }) {
                    if isEditing {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
             

                    }else {
                        Image(.squarePencil)
                            .resizable()
                           
                    }
                }
                .frame(width: 24, height: 24)
                .foregroundColor(.black)
                .padding(.trailing)
                .padding(.leading, 78)
            }
            
            if let imageURL = authViewModel.user?.profileImageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } placeholder: {
                    ProgressView()
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
            }
            
            if isEditing {
                Button("Change Profile Picture") {
                    showImagePicker = true
                }
            }
            
            if isEditing {
                TextField("Name", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Bio", text: $userBio)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Text(userName)
                    .font(.Gilroy(weight: .bold, size: 22))
                    .padding(.top, 19)
                Text(userBio)
                    .font(.DMSans(weight: .medium, size: 13))
                    .foregroundColor(.appGray2.opacity(0.6))
            }
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading) {
            Text("Recent Achievements")
                .font(.Gilroy(weight: .bold, size: 16))
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    AchievementCard(title: "First Check-In", iconName: "BeginnerBadge")
                    AchievementCard(title: "7-Day Streak", iconName: "BeginnerBadge")
                    AchievementCard(title: "Habit Master", iconName: "BeginnerBadge")
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var recentCheckInsSection: some View {
        VStack(alignment: .leading) {
            Text("Recent Check-Ins")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(1...3, id: \.self) { _ in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Feeling great!")
                    Spacer()
                    Text("2h ago")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
    
    private var habitsSection: some View {
        VStack(alignment: .leading) {
            Text("Habits")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(["Meditation", "Exercise", "Reading", "Journaling"], id: \.self) { habit in
                HStack {
                    Image(systemName: "circle.fill")
                        .foregroundColor(.blue)
                    Text(habit)
                    Spacer()
                    Text("Daily")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let iconName: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: 107, height: 115)
                .background(.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.89, green: 0.89, blue: 0.89), lineWidth: 0.5)
                )
            
            VStack(alignment: .leading,spacing: 5) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 23, height: 23)
                
                Text(title)
                    .font(.DMSans(weight: .regular, size: 13))
                    .foregroundColor(Color.appGray2.opacity(0.7))
                    .padding(.top, 19)
                
                Text(value)
                    .font(.Gilroy(weight: .bold, size: 16))
                    .foregroundColor(Color.appBlack)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 13)
        }
    }
}

struct AchievementCard: View {
    let title: String
    let iconName: String
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .foregroundColor(Color.appWhite)
                    .frame(width: 80, height: 80)
                
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 39, height: 39)
            }
            
            Text(title)
                .font(.DMSans(weight: .regular, size: 13))
                .foregroundColor(Color.appBlack)
                .multilineTextAlignment(.center)
        }
        .frame(width: 93, height: 127)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthViewModel = AuthViewModel()
        mockAuthViewModel.user = User(
            id: "123",
            email: "test@example.com",
            name: "Test User",
            profileImageURL: nil,
            bio: "Test bio",
            checkInCount: 5,
            lastCheckInDate: Date(),
            currentStreak: 3
        )
        return ProfileView(authViewModel: mockAuthViewModel)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
