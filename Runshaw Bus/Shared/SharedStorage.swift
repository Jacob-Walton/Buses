//
//  SharedStorage.swift
//  Runshaw Bus
//
//  Created by Jacob on 24/04/2026.
//

import Foundation

enum SharedStorage {
    // Must match the App Group entitlement registered in the developer portal
    static let appGroup = "group.com.konpeki.Buses"
    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }
    
    // Keys
    static let favoritesKey = "favoriteRoutes"
    static let lastNotifiedKey = "lastNotifiedByRoute"
    static let cachedBusesKey = "cachedBuses"
    static let cachedAtKey = "cachedAt"
}
