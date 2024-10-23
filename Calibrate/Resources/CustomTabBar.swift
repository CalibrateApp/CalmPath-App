//
//  TabBarView.swift
//  Calibrate
//
//  Created by Hadi on 23/10/2024.
//

import SwiftUI

struct CustomTabBar : View {
    
    @Binding var selectedTab: Int
    
    var height: CGFloat
    
    var body: some View {
        
        HStack(spacing: 0) {
            
            BarItem(image: UIImage(named: "home")!, index: 0, selectedIndex:  $selectedTab)
            BarItem(image: UIImage(systemName: "star")!, index: 1, selectedIndex:  $selectedTab)
            BarItem(image: UIImage(systemName: "book")!, index: 2, selectedIndex:  $selectedTab)
            BarItem(image: UIImage(named: "person")!, index: 3, selectedIndex:  $selectedTab)
        }
        .frame(height: height, alignment: .top)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 50, y: 0)
    }
}

struct BarItem : View {
    var image: UIImage
    var index: Int
    @Binding var selectedIndex: Int
    var body: some View{
        Button {
            selectedIndex = index
        } label: {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(selectedIndex == index ? Color.appBlack : Color.appGray4)
                    .frame(width: 20, height: 20)
                
                //if selectedIndex == index{
                    Circle()
                    .fill(selectedIndex == index ? Color.appBlack : Color.clear)
                        .frame(width: 4, height: 4)
               // }
                    
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 18)
        }
    }
}
