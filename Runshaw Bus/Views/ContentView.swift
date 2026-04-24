//
//  ContentView.swift
//  Runshaw Bus
//
//  Created by Jacob on 24/04/2026.
//

import SwiftUI

enum FilterOption: String, CaseIterable, Identifiable {
    case all = "All", arrived = "Arrived", waiting = "Waiting"
    var id: Self { self }
}

struct ContentView: View {
    private let apiService = ApiService()
    
    @Environment(FavoritesStore.self) private var favorites
    
    @State private var buses: [Bus] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var searchText = ""
    @State private var filter: FilterOption = .all
    @State private var lastUpdated: Date? = nil
    // @State private var isActivityActive = ActivityManager.isActive
    @State private var previousFavoriteArrivedNumbers: Set<String> = {
        guard let data = SharedStorage.defaults.data(forKey: SharedStorage.cachedBusesKey),
              let buses = try? JSONDecoder().decode([Bus].self, from: data),
              let cachedAt = SharedStorage.defaults.object(forKey: SharedStorage.cachedAtKey) as? Date,
              Calendar.current.isDateInToday(cachedAt)
        else { return [] }
        return Set(buses.filter(\.hasArrived).map(\.number))
    }()
    
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 10)]
    
    private var arrivedCount: Int { buses.filter(\.hasArrived).count }
    private var waitingCount: Int { buses.count - arrivedCount }
    
    private var filteredBuses: [Bus] {
        buses.filter { bus in
            let matchesSearch = searchText.isEmpty ||
                bus.number.localizedCaseInsensitiveContains(searchText)
            let matchesFilter: Bool = switch filter {
                case .all: true
                case .arrived: bus.hasArrived
                case .waiting: !bus.hasArrived
            }
            return matchesSearch && matchesFilter
        }
        .sorted { a, b in
            if favorites.isFavorite(a) != favorites.isFavorite(b) {
                return favorites.isFavorite(a)
            }
            return false
        }
    }
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    content
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .refreshable {
                await fetchData()
            }
            
            if isLoading && buses.isEmpty {
                ProgressView().controlSize(.large)
            }
        }
        .task { await fetchData() }
        .task { await autoRefreshLoop() }
        .onChange(of: favorites.favorites) { old, new in
            if old.isEmpty && !new.isEmpty {
                // TODO: Request notification permissions
            }
        }
    }
    
    // MARK: - Components
    
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Departures")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if let error = errorMessage, buses.isEmpty {
            errorState(error)
        } else if !buses.isEmpty && filteredBuses.isEmpty {
            emptyState
        } else {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(filteredBuses) { bus in
                    RouteCard(bus: bus)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.snappy, value: filteredBuses)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No matches")
                .font(.system(.headline, design: .rounded))
            Text("Try a different route or filter.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.orange)
            Text("Couldn't load departures")
                .font(.system(.headline, design: .rounded))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try again") {
                Task { await fetchData() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Utility Functions
    
    private func fetchData() async {
        isLoading = true
        errorMessage = nil
        
        let result = await apiService.getData()
        
        guard !Task.isCancelled else {
            isLoading = false
            return
        }
        
        if let data = result {
            withAnimation(.snappy) { buses = data }
            
            let nowArrived = Set(data.filter { favorites.isFavorite($0) && $0.hasArrived }.map(\.number))
            let newArrivals = nowArrived.subtracting(previousFavoriteArrivedNumbers)
            if !newArrivals.isEmpty {
                Haptics.success()
            }
            previousFavoriteArrivedNumbers = nowArrived
            lastUpdated = Date()
            
            if let encoded = try? JSONEncoder().encode(data) {
                SharedStorage.defaults.set(encoded, forKey: SharedStorage.cachedBusesKey)
                SharedStorage.defaults.set(Date(), forKey: SharedStorage.cachedAtKey)
            }
            // WidgetCenter.shared.reloadAllTimelines()
            // TODO: Update live activity
            // await ActivityManager.update(with: data)
            // isActivityActive = ActivityManager.isActive
        } else if buses.isEmpty {
            errorMessage = "Check your connection and try again."
            Haptics.error()
        }
        isLoading = false
    }
    
    // Runs for the lifetime of the view. Fetches every 2 min during active window;
    // sleeps until window open if called early; exits if outside window with no future open time.
    private func autoRefreshLoop() async {
        while !Task.isCancelled {
            if isInActiveWindow() {
                try? await Task.sleep(for: .seconds(2 * 60))
                if !Task.isCancelled, isInActiveWindow() { await fetchData() }
            } else if let delay = secondsUntilWindowOpen(), delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            } else {
                return
            }
        }
    }
    
    private func isInActiveWindow() -> Bool {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        guard (2...6).contains(weekday) else { return false }
        let c = cal.dateComponents([.hour, .minute], from: now)
        guard let h = c.hour, let m = c.minute else { return false }
        let mins = h * 60 + m
        return (15*60 ... 16*60 + 30).contains(mins)
    }
    
    private func secondsUntilWindowOpen() -> Double? {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        guard (2...6).contains(weekday) else { return nil }
        let c = cal.dateComponents([.hour, .minute, .second], from: now)
        guard let h = c.hour, let m = c.minute, let s = c.second else { return nil }
        let nowSecs  = h * 3600 + m * 60 + s
        let winStart = 15 * 3600
        let winEnd   = 16 * 3600 + 30 * 60
        guard nowSecs < winEnd else { return nil }
        return Double(max(0, winStart - nowSecs))
    }
}

#Preview {
    ContentView()
        .environment(FavoritesStore())
}
