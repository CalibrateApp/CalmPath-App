import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct User: Codable, Identifiable {
    let id: String
    var email: String
    var name: String
    var profileImageURL: String?
    var bio: String?
    var checkInCount: Int
    var lastCheckInDate: Date?
    var currentStreak: Int
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, profileImageURL, bio, checkInCount, lastCheckInDate, currentStreak
    }
    
    init(id: String, email: String, name: String, profileImageURL: String? = nil, bio: String? = nil, checkInCount: Int = 0, lastCheckInDate: Date? = nil, currentStreak: Int = 0) {
        self.id = id
        self.email = email
        self.name = name
        self.profileImageURL = profileImageURL
        self.bio = bio
        self.checkInCount = checkInCount
        self.lastCheckInDate = lastCheckInDate
        self.currentStreak = currentStreak
    }
}

struct UserData {
    var email = ""
    var password = ""
}

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var userData = UserData()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        if let firebaseUser = Auth.auth().currentUser {
            isAuthenticated = true
            fetchUserProfile(userId: firebaseUser.uid)
        } else {
            isAuthenticated = false
            user = nil
        }
    }
    
    func signIn() {
        Auth.auth().signIn(withEmail: userData.email, password: userData.password) { [weak self] authResult, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }
            
            if let firebaseUser = authResult?.user {
                self?.isAuthenticated = true
                print("User signed in: \(firebaseUser.uid)")
                self?.fetchUserProfile(userId: firebaseUser.uid)
            }
        }
    }
    
    func signUp() {
        Auth.auth().createUser(withEmail: userData.email, password: userData.password) { [weak self] authResult, error in
            if let error = error {
                print("Error signing up: \(error.localizedDescription)")
                return
            }
            
            if let firebaseUser = authResult?.user {
                self?.isAuthenticated = true
                print("User signed up: \(firebaseUser.uid)")
                self?.createUserProfile(userId: firebaseUser.uid, email: firebaseUser.email ?? "")
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            user = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    private func createUserProfile(userId: String, email: String) {
        let newUser = User(id: userId, email: email, name: "", profileImageURL: nil, bio: nil, checkInCount: 0, lastCheckInDate: nil, currentStreak: 0)
        saveUserProfile(user: newUser)
    }
    
    func saveUserProfile(user: User) {
        do {
            var userData = try Firestore.Encoder().encode(user)
            // Ensure Timestamp is used for lastCheckInDate
            if let lastCheckInDate = user.lastCheckInDate {
                userData["lastCheckInDate"] = Timestamp(date: lastCheckInDate)
            }
            db.collection("users").document(user.id).setData(userData, merge: true) { error in
                if let error = error {
                    print("Error saving user profile: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.user = user
                        self.objectWillChange.send()
                        print("User profile saved successfully: \(user)")
                    }
                }
            }
        } catch {
            print("Error encoding user profile: \(error.localizedDescription)")
        }
    }
    
    public func fetchUserProfile(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                do {
                    let data = document.data() ?? [:]
                    var user = try document.data(as: User.self)
                    
                    // Explicitly update fields from document data
                    user.checkInCount = data["checkInCount"] as? Int ?? 0
                    user.lastCheckInDate = (data["lastCheckInDate"] as? Timestamp)?.dateValue()
                    user.currentStreak = data["currentStreak"] as? Int ?? 0
                    
                    DispatchQueue.main.async {
                        self?.user = user
                        self?.objectWillChange.send()
                        print("User profile fetched and updated: \(user)")
                        
                        // Print individual fields for debugging
                        print("checkInCount: \(user.checkInCount)")
                        print("lastCheckInDate: \(String(describing: user.lastCheckInDate))")
                        print("currentStreak: \(user.currentStreak)")
                    }
                    
                    // Save the updated user profile
                    self?.saveUserProfile(user: user)
                } catch {
                    print("Error decoding user: \(error.localizedDescription)")
                    print("Document data: \(document.data() ?? [:])")
                    
                    // If decoding fails, create a new user with available data
                    if let data = document.data() {
                        let newUser = User(
                            id: data["id"] as? String ?? userId,
                            email: data["email"] as? String ?? "",
                            name: data["name"] as? String ?? "",
                            profileImageURL: data["profileImageURL"] as? String,
                            bio: data["bio"] as? String,
                            checkInCount: data["checkInCount"] as? Int ?? 0,
                            lastCheckInDate: (data["lastCheckInDate"] as? Timestamp)?.dateValue(),
                            currentStreak: data["currentStreak"] as? Int ?? 0
                        )
                        self?.saveUserProfile(user: newUser)
                    }
                }
            } else {
                print("User document does not exist for userId: \(userId)")
                self?.createUserProfile(userId: userId, email: Auth.auth().currentUser?.email ?? "")
            }
        }
    }
    
    public func refreshCurrentUserProfile() {
        if let userId = Auth.auth().currentUser?.uid {
            fetchUserProfile(userId: userId)
        }
    }
    
    func updateUserProfile(name: String, bio: String?) {
        guard var updatedUser = user else { return }
        updatedUser.name = name
        updatedUser.bio = bio
        saveUserProfile(user: updatedUser)
    }
    
    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        let storageRef = storage.reference().child("profile_images/\(user?.id ?? UUID().uuidString).jpg")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let url = url {
                    completion(.success(url.absoluteString))
                }
            }
        }
    }
    
    func updateProfileImageURL(_ url: String) {
        guard var updatedUser = user else { return }
        updatedUser.profileImageURL = url
        saveUserProfile(user: updatedUser)
    }
    
    func saveCheckIn(anxietyLevel: Double, consumedCaffeine: Bool, consumedAlcohol: Bool, consumedMedication: Bool, wentToGym: Bool, followedIntermittentFasting: Bool, didMeditation: Bool, hadColdShower: Bool, additionalNotes: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let checkInData: [String: Any] = [
            "userId": userId,
            "anxietyLevel": anxietyLevel,
            "consumedCaffeine": consumedCaffeine,
            "consumedAlcohol": consumedAlcohol,
            "consumedMedication": consumedMedication,
            "wentToGym": wentToGym,
            "followedIntermittentFasting": followedIntermittentFasting,
            "didMeditation": didMeditation,
            "hadColdShower": hadColdShower,
            "additionalNotes": additionalNotes,
            "date": Timestamp(date: Date())
        ]
        
        db.collection("checkIns").addDocument(data: checkInData) { [weak self] error in
            if let error = error {
                print("Error saving check-in: \(error.localizedDescription)")
            } else {
                self?.updateCheckInStats()
            }
        }
    }
    
    private func updateCheckInStats() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        let checkInsRef = db.collection("checkIns").whereField("userId", isEqualTo: userId)
        
        // First, get the check-in count
        checkInsRef.getDocuments { [weak self] (querySnapshot, error) in
            if let error = error {
                print("Error getting check-in documents: \(error)")
                return
            }
            
            let checkInCount = querySnapshot?.documents.count ?? 0
            
            // Update user document with new check-in stats
            userRef.updateData([
                "checkInCount": checkInCount,
                "lastCheckInDate": Timestamp(date: Date()),
                "currentStreak": FieldValue.increment(Int64(1))
            ]) { error in
                if let error = error {
                    print("Error updating user document: \(error)")
                } else {
                    DispatchQueue.main.async {
                        self?.user?.checkInCount = checkInCount
                        self?.user?.lastCheckInDate = Date()
                        self?.user?.currentStreak += 1
                        self?.objectWillChange.send()
                    }
                }
            }
        }
    }
}

extension Date {
    func stripTime() -> Date? {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return Calendar.current.date(from: components)
    }
}