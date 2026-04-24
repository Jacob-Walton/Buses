//
//  ContentView.swift
//  Runshaw Bus
//
//  Created by Jacob on 24/04/2026.
//

import SwiftUI

struct ContentView: View {
    private let apiService = ApiService()
    
    @State private var buses: [Bus] = []
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
