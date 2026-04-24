//
//  Runshaw_Bus_Widget.swift
//  Runshaw Bus Widget
//
//  Created by Jacob on 24/04/2026.
//

import SwiftUI
import WidgetKit

struct FavoriteBusEntry: TimelineEntry {
    let date: Date
    let favorites: [Bus]
    let cachedAt: Date?
}


struct FavoriteBusProvider: TimelineProvider {
    func placeholder(in context: Context) -> FavoriteBusEntry {
        FavoriteBusEntry(
            date: .now,
            favorites: [
                Bus(id: 0, number: "800", bay: "A7"),
                Bus(id: 1, number: "962", bay: "TBC")
            ],
            cachedAt: .now
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FavoriteBusEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FavoriteBusEntry>) -> Void) {
        let entry = loadEntry()
        completion(Timeline(entries: [entry], policy: .after(nextRefreshDate())))
    }

    private func nextRefreshDate() -> Date {
        let cal = Calendar.current
        let now = Date()
        let in2 = now.addingTimeInterval(2 * 60)
        if isInWindow(in2) { return in2 }
        var candidate = now
        for _ in 0..<7 {
            candidate = cal.date(byAdding: .day, value: 1, to: candidate) ?? candidate
            if (2...6).contains(cal.component(.weekday, from: candidate)) {
                return cal.date(bySettingHour: 15, minute: 0, second: 0, of: candidate) ?? in2
            }
        }
        return in2
    }

    private func isInWindow(_ date: Date) -> Bool {
        let cal = Calendar.current
        guard (2...6).contains(cal.component(.weekday, from: date)) else { return false }
        let c = cal.dateComponents([.hour, .minute], from: date)
        guard let h = c.hour, let m = c.minute else { return false }
        let mins = h * 60 + m
        return (15*60 ... 16*60 + 30).contains(mins)
    }

    private func loadEntry() -> FavoriteBusEntry {
        let defaults = SharedStorage.defaults
        let favoriteNumbers = Set(defaults.stringArray(forKey: SharedStorage.favoritesKey) ?? [])

        var allBuses: [Bus] = []
        if let data = defaults.data(forKey: SharedStorage.cachedBusesKey),
           let decoded = try? JSONDecoder().decode([Bus].self, from: data) {
            allBuses = decoded
        }

        let cachedAt = defaults.object(forKey: SharedStorage.cachedAtKey) as? Date

        let favorites = allBuses
            .filter { favoriteNumbers.contains($0.number) }
            .sorted { a, b in
                if a.hasArrived != b.hasArrived { return a.hasArrived }
                return a.number < b.number
            }

        return FavoriteBusEntry(date: .now, favorites: favorites, cachedAt: cachedAt)
    }
}

// MARK: - Views

struct BusWidget: View {
    @Environment(\.widgetFamily) var family
    let entry: FavoriteBusEntry

    var body: some View {
        switch family {
        case .accessoryRectangular: rectangularView
        case .accessoryInline:     inlineView
        case .systemSmall:         smallView
        case .systemMedium:        mediumView
        default:                   rectangularView
        }
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            if entry.favorites.isEmpty {
                Label("No favourites", systemImage: "star")
                    .font(.caption)
            } else {
                ForEach(entry.favorites.prefix(3)) { bus in
                    HStack(spacing: 6) {
                        Text(bus.number)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .frame(minWidth: 32, alignment: .leading)
                        Text(bus.hasArrived ? "Bay \(bus.bay)" : "Waiting")
                            .font(.caption2)
                            .foregroundStyle(bus.hasArrived ? .primary : .secondary)
                        Spacer()
                        Image(systemName: bus.hasArrived ? "checkmark.circle.fill" : "circle")
                            .font(.caption2)
                    }
                }
            }
        }
    }

    private var inlineView: some View {
        let arrived = entry.favorites.filter(\.hasArrived)
        if let first = arrived.first {
            return Text("\(Image(systemName: "bus")) \(first.number) Bay \(first.bay)")
        } else if let first = entry.favorites.first {
            return Text("\(Image(systemName: "bus")) \(first.number) waiting")
        } else {
            return Text("\(Image(systemName: "bus")) No favourites")
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bus.fill")
                    .font(.caption)
                Text("Buses")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(.secondary)

            if entry.favorites.isEmpty {
                Spacer()
                Text("Pick favourites in the app")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(entry.favorites.prefix(3)) { bus in
                    HStack {
                        Text(bus.number)
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        Spacer()
                        Text(bus.hasArrived ? bus.bay : "-")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(bus.hasArrived ? .green : .secondary)
                    }
                }
                Spacer()
            }
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Departures", systemImage: "bus.fill")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let cachedAt = entry.cachedAt {
                    Text(cachedAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if entry.favorites.isEmpty {
                Text("No favourite routes yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 6) {
                    ForEach(entry.favorites.prefix(4)) { bus in
                        GridRow {
                            Text(bus.number)
                                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            Text(bus.hasArrived ? "Bay \(bus.bay)" : "Waiting")
                                .font(.subheadline)
                                .foregroundStyle(bus.hasArrived ? .primary : .secondary)
                            Image(systemName: bus.hasArrived ? "checkmark.circle.fill" : "clock")
                                .foregroundStyle(bus.hasArrived ? .green : .orange)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Widget

struct Runshaw_Bus_Widget: Widget {
    let kind = "BusesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FavoriteBusProvider()) { entry in
            BusWidget(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("My Buses")
        .description("Favourite routes at a glance.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryInline,
            .systemSmall,
            .systemMedium
        ])
    }
}

private let previewEntry = FavoriteBusEntry(
    date: .now,
    favorites: [
        Bus(id: 0, number: "800", bay: "A7"),
        Bus(id: 1, number: "962", bay: "TBC"),
        Bus(id: 2, number: "819", bay: "C3")
    ],
    cachedAt: .now
)

#Preview("Small", as: .systemSmall) {
    Runshaw_Bus_Widget()
} timeline: {
    previewEntry
}

#Preview("Medium", as: .systemMedium) {
    Runshaw_Bus_Widget()
} timeline: {
    previewEntry
}

#Preview("Rectangular", as: .accessoryRectangular) {
    Runshaw_Bus_Widget()
} timeline: {
    previewEntry
}
