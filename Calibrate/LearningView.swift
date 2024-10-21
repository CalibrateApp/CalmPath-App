import SwiftUI

struct LearningView: View {
    
    @State var text: String = ""
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    var body: some View {
        VStack(alignment: .leading) {
            Text("Learning")
                .font(.Gilroy(weight: .bold, size: 22))
            
            customTextField(text: $text)
                            .padding(.top, 16)
            
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Understanding Anxiety")
                        .padding(.top, 23)
                        .padding(.bottom, 8)
                        .font(.Gilroy(weight: .bold, size: 16))
                    
                    LazyVGrid(columns: columns) {
                        
                        customCard(icon: .tension, text: "What is Anxiety?", time: "12m")
                        
                        customCard(icon: .causes, text: "Causes and Triggers", time: "12m")
                        
                        customCard(icon: .disorder, text: "Anxiety Disorders", time: "12m")
                        
                        customCard(icon: .effects, text: "Effects on the body", time: "12m")
                        
                    }
                    Text("Breathing Techniques")
                        .font(.Gilroy(weight: .bold, size: 16))
                        .padding(.top, 33)
                        .padding(.bottom, 8)
                    
                    LazyVGrid(columns: columns) {
                        
                        customCard(icon: .breathing, text: "Breathing", time: "12m")
                        
                        customCard(icon: .exercise, text: "Exercise", time: "12m")
                    }
                }
            }
        }
        .padding(.horizontal, 15)
    }
}

struct LearningView_Previews: PreviewProvider {
    static var previews: some View {
        LearningView()
    }
}


struct customCard: View {
    
    let icon: ImageResource
    let text: String
    let time: String
    let columnWidth: CGFloat = (UIScreen.main.bounds.width - 41) / 2
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Image(icon)
                .resizable()
                .frame(height: 122)
                .padding(.horizontal, 8)
                .padding(.vertical, 9)
                .clipShape(.rect(cornerRadius: 8))
            
            Text(text)
                .font(.DMSans(weight: .medium, size: 14))
                .padding(.horizontal, 11)
                .padding(.bottom, 5)
            
            
            Text(time)
                .font(.DMSans(weight: .regular, size: 12))
                .foregroundStyle(.colorGray)
                .padding(.horizontal, 11)
                .padding(.bottom, 14)
            
        }
        .frame(width: columnWidth)
        .background(RoundedRectangle(cornerRadius: 10)
            .foregroundStyle(.colorWhite))
        .shadow(radius: 0.3)
    }
    
}
struct customTextField: View {
    
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search", text: $text)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
  }


    
    



