//
//  FavoritesStore.swift
//  Runshaw Bus
//
//  Created by Jacob on 24/04/2026.
//

import SwiftUI

@Observable
final class FavoritesStore {
    var favorites: Set<String> {
        didSet {
            SharedStorage.defaults.set(Array(favorites), forKey:
                                        SharedStorage.favoritesKey)
        }
    }
    
    init() {
        let stored = SharedStorage.defaults.stringArray(forKey: SharedStorage.favoritesKey) ?? []
        self.favorites = Set(stored)
    }
    
    func isFavorite(_ bus: Bus) -> Bool {
        favorites.contains(bus.number)
    }
    
    func toggle(_ bus: Bus) {
        if favorites.contains(bus.number) {
            favorites.remove(bus.number)
        } else {
            favorites.insert(bus.number)
        }
    }
    
    // MARK: - Notifications
    
    func hasNotifiedToday(route: String) -> Bool {
        guard let date = SharedStorage.defaults.object(forKey: "lastNotified_\(route)") as? Date else { return false }
        return Calendar.current.isDateInToday(date)
    }

    func markNotified(route: String) {
        SharedStorage.defaults.set(Date(), forKey: "lastNotified_\(route)")
    }
}
