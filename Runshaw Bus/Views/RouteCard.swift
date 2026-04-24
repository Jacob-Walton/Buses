//
//  RouteCard.swift
//  Runshaw Bus
//
//  Created by Jacob on 24/04/2026.
//

import SwiftUI

struct RouteCard: View {
    let bus: Bus
    @Environment(FavoritesStore.self) private var favorites

    private var isFavourite: Bool { favorites.isFavorite(bus) }

    var body: some View {
        VStack(spacing: 4) {
            Text(bus.number)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(bus.hasArrived ? .white : .primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Group {
                if bus.hasArrived {
                    Text("Bay \(bus.bay)")
                        .foregroundStyle(.white.opacity(0.95))
                } else {
                    Label("Waiting", systemImage: "clock")
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleAndIcon)
                }
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 74)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(bus.hasArrived
                      ? AnyShapeStyle(Color.green.gradient)
                      : AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
        }
        .overlay(alignment: .topTrailing) {
            if isFavourite {
                Image(systemName: "star.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.yellow)
                    .padding(6)
                    .background(.black.opacity(0.25), in: Circle())
                    .padding(6)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            Haptics.toggle()
            withAnimation(.snappy) { favorites.toggle(bus) }
        }
    }
}

struct StatPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text("\(count)")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isSelected
                                   ? AnyShapeStyle(Color.primary)
                                   : AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Arrived") {
    RouteCard(bus: Bus(id: 0, number: "800", bay: "A7"))
        .environment(FavoritesStore())
        .frame(width: 120)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Waiting") {
    RouteCard(bus: Bus(id: 0, number: "962", bay: "TBC"))
        .environment(FavoritesStore())
        .frame(width: 120)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("StatPill") {
    HStack {
        StatPill(count: 3, label: "arrived", color: .green)
        StatPill(count: 5, label: "waiting", color: .orange)
    }
    .padding()
}

#Preview("FilterPill") {
    HStack {
        FilterPill(title: "All", isSelected: true) {}
        FilterPill(title: "Arrived", isSelected: false) {}
        FilterPill(title: "Waiting", isSelected: false) {}
    }
    .padding()
}
