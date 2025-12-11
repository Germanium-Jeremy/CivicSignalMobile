//
//  MapView.swift
//  CivicSignal
//
//  Created by Jeremy Nk on 27/11/2025.
//

import SwiftUI

struct MapView: View {
    var body: some View {
        ZStack {
            Color.mainBackground
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Map")
                    .font(AppFont.title)
                    .foregroundColor(.almostBlack)
                    .padding(.top, 24)
                
                Text("This is a placeholder for the map and locations screen.")
                    .font(AppFont.body)
                    .foregroundColor(.neutralGray)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    MapView()
}
