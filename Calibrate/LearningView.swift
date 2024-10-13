import SwiftUI

struct LearningView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("Learning")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Coming Soon!")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("We're working hard to bring you exciting learning content. Stay tuned for updates!")
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}

struct LearningView_Previews: PreviewProvider {
    static var previews: some View {
        LearningView()
    }
}