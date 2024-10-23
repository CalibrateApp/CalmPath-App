import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth  // Add this line

struct Technique: Identifiable, Codable {
    let id: String
    let name: String
    let category: String
    let description: String
    let imageURL: String
    var upvotes: Int
    var downvotes: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, category, description, imageURL, upvotes, downvotes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(String.self, forKey: .category)
        description = try container.decode(String.self, forKey: .description)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        
        // Handle both String and Int for upvotes and downvotes
        if let upvotesInt = try? container.decode(Int.self, forKey: .upvotes) {
            upvotes = upvotesInt
        } else if let upvotesString = try? container.decode(String.self, forKey: .upvotes),
                  let upvotesInt = Int(upvotesString) {
            upvotes = upvotesInt
        } else {
            upvotes = 0
        }
        
        if let downvotesInt = try? container.decode(Int.self, forKey: .downvotes) {
            downvotes = downvotesInt
        } else if let downvotesString = try? container.decode(String.self, forKey: .downvotes),
                  let downvotesInt = Int(downvotesString) {
            downvotes = downvotesInt
        } else {
            downvotes = 0
        }
    }
}

class TechniqueViewModel: ObservableObject {
    @Published var techniques: [Technique] = []
    private var db = Firestore.firestore()
    
    init() {
        fetchTechniques()
    }
    
    func fetchTechniques() {
        print("Fetching techniques...")
        db.collection("techniques").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            print("Number of documents: \(documents.count)")
            
            self.techniques = documents.compactMap { queryDocumentSnapshot -> Technique? in
                do {
                    let technique = try queryDocumentSnapshot.data(as: Technique.self)
                    print("Fetched technique: \(technique.name), Category: \(technique.category), Upvotes: \(technique.upvotes), Downvotes: \(technique.downvotes)")
                    return technique
                } catch {
                    print("Error decoding technique: \(error)")
                    return nil
                }
            }
            
            print("Total techniques fetched: \(self.techniques.count)")
            
            // Force UI update
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    func vote(for technique: Technique, voteType: VoteType) {
        // Voting logic remains the same
    }
}

struct TopRatedView: View {
    @Binding var selectedTab: Int
    @StateObject private var viewModel = TechniqueViewModel()
    @State private var searchText = ""
    @State private var activeCategory = "All"
    
    let categories = ["All", "Apps", "Meditation", "Relaxation", "Exercise", "Supplements", "Medication"]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Top-Rated for Community")
                    .font(.Gilroy(weight: .bold, size: 24))
                    .padding(.horizontal)
                
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 15)
                    .padding(.bottom, 19)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            CategoryButton(title: category, isActive: activeCategory == category) {
                                activeCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                if viewModel.techniques.isEmpty {
                    Text("No techniques available. Please check your internet connection and try again.")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    ScrollView {
                        ForEach(filteredTechniques) { technique in
                            TechniqueRow(technique: technique)
                        }
                        .padding(.top, 19)
                        .padding(.bottom, 12)
                    }
                    .padding(.bottom, 65)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchTechniques()
            }
        }
    }
    
    var filteredTechniques: [Technique] {
        let categoryFiltered = activeCategory == "All" ? viewModel.techniques : viewModel.techniques.filter { $0.category.lowercased() == activeCategory.lowercased() }
        return categoryFiltered.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.upvotes - $0.downvotes > $1.upvotes - $1.downvotes }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search", text: $text)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CategoryButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? Color.black : Color.appWhite)
                .foregroundColor(isActive ? .white : .black)
                .cornerRadius(20)
        }
    }
}

struct TechniqueRow: View {
    let technique: Technique
    
    var body: some View {

        
        HStack {
            Image(technique.imageURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 53, height: 53)
                .clipShape(.rect(cornerRadius: 8))
                .padding(9)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(technique.name)
                    .font(.DMSans(weight: .medium, size: 13))
                    .foregroundColor(.black)
                
                Text(technique.description)
                    .font(.DMSans(weight: .regular, size: 12))
                    .foregroundStyle(.appGray2).opacity(0.6)
            }
            .padding(.trailing, 5)
            
            
            
            Spacer()
            
            HStack(spacing: 17) {
                VoteView(count: technique.upvotes, isUpvote: true)
                VoteView(count: technique.downvotes, isUpvote: false)
            }
            .padding(.trailing, 27)
        }
        .background(RoundedRectangle(cornerRadius: 10))
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.1), radius: 14, x: 10, y: 0)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 15)
    }
}

struct VoteView: View {
    let count: Int
    let isUpvote: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(isUpvote ? "akar-icons_arrow-up-thick" : "akar-icons_arrow-down-thick")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 14, height: 14)
            Text("\(count)")
                .font(Font.custom("DM Sans", size: 13).weight(.semibold))
        }
        .foregroundColor(color)
    }
    
    private var color: Color {
        if isUpvote && count > 0 {
            return Color(red: 0.23, green: 0.62, blue: 0.90)
        } else {
            return Color(red: 0.44, green: 0.44, blue: 0.44)
        }
    }
}

enum ArrowDirection {
    case up, down
}

struct ThickArrow: View {
    let pointing: ArrowDirection
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = min(geometry.size.width, geometry.size.height)
                let height = width
                let thickness = width * 0.3
                
                switch pointing {
                case .up:
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: width / 2, y: 0))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: width - thickness, y: height))
                    path.addLine(to: CGPoint(x: width / 2, y: thickness))
                    path.addLine(to: CGPoint(x: thickness, y: height))
                    path.closeSubpath()
                case .down:
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: width / 2, y: height))
                    path.addLine(to: CGPoint(x: width, y: 0))
                    path.addLine(to: CGPoint(x: width - thickness, y: 0))
                    path.addLine(to: CGPoint(x: width / 2, y: height - thickness))
                    path.addLine(to: CGPoint(x: thickness, y: 0))
                    path.closeSubpath()
                }
            }
            .fill()
        }
    }
}

enum VoteType: String {
    case up = "upvotes"
    case down = "downvotes"
}

struct TopRatedView_Previews: PreviewProvider {
    static var previews: some View {
        TopRatedView(selectedTab: .constant(1))
    }
}

