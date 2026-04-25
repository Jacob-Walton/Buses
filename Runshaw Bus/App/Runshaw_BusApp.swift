//
//  Runshaw_BusApp.swift
//  Runshaw Bus
//
//  Created by Jacob on 24/04/2026.
//

import SwiftUI

@main
struct Runshaw_BusApp: App {
    @State private var favorites = FavoritesStore()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        BackgroundRefresh.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(favorites)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                BackgroundRefresh.schedule()
            }
        }
    }
}
