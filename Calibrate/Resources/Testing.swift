////
////  Testing.swift
////  Calibrate
////
////  Created by Hadi on 22/10/2024.
////
//
//import SwiftUI
//
//struct OptionButton: View {
//    let emoji: String
//    let title: String
//    @Binding var isSelected: Bool
//
//    var body: some View {
//        HStack {
//            Text(emoji)
//                .font(.system(size: 20)) // Customize emoji size if needed
//            
//            Text(title)
//                .foregroundColor(isSelected ? .white : .black) // Use standard colors
//                .font(.DMSans(weight: .medium, size: 13))
//        }
//        .padding()
//        .background(RoundedRectangle(cornerRadius: 100)
//            .foregroundColor(isSelected ? Color.appBlue : Color.appWhite) // Ensure you have these colors defined
//            .frame(width: 97, height: 37))
//        .onTapGesture {
//            isSelected.toggle() // Toggle the selection state
//        }
//        .animation(.easeInOut) // Optional: add animation for smooth transitions
//    }
//}
//
//// Example usage in a parent view
//struct abcView: View {
//    @State private var isFirstButtonSelected: Bool = false
//    @State private var isSecondButtonSelected: Bool = false
//
//    var body: some View {
//        VStack {
//            OptionButton(emoji: "😀", title: "Option 1", isSelected: $isFirstButtonSelected)
//            OptionButton(emoji: "😎", title: "Option 2", isSelected: $isSecondButtonSelected)
//            
//            Text(isFirstButtonSelected ? "Option 1 Selected!" : "Option 1 Not Selected")
//            Text(isSecondButtonSelected ? "Option 2 Selected!" : "Option 2 Not Selected")
//        }
//        .padding()
//    }
//}
//
//struct abcView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
//
