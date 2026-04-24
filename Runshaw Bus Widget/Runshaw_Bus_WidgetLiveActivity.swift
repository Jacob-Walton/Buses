//
//  Runshaw_Bus_WidgetLiveActivity.swift
//  Runshaw Bus Widget
//
//  Created by Jacob on 24/04/2026.
//

import SwiftUI
import ActivityKit
import WidgetKit

struct Runshaw_Bus_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BusActivityAttributes.self) { context in
            LockScreenView(context: context)
                .padding()
                .activityBackgroundTint(.black.opacity(0.3))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    let arrived = context.state.buses.filter { $0.bay != nil }.count
                    let total = context.state.buses.count
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(arrived)/\(total)")
                            .font(.system(.title, design: .rounded, weight: .heavy))
                            .foregroundStyle(.white)
                        Text("arrived")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let first = context.state.buses.first(where: { $0.bay != nil }) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(first.route)
                                .font(.system(.headline, design: .rounded, weight: .heavy))
                                .foregroundStyle(.white)
                            Text("Bay \(first.bay!)")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundStyle(.green)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        ForEach(context.state.buses, id: \.route) { bus in
                            VStack(spacing: 2) {
                                Text(bus.route)
                                    .font(.system(.caption, design: .rounded, weight: .bold))
                                    .foregroundStyle(.white)
                                if let bay = bus.bay {
                                    Text("Bay \(bay)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "clock")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                    Text("Updated \(context.state.lastUpdated, style: .time)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            } compactLeading: {
                Image(systemName: "bus.fill")
                    .foregroundStyle(.white)
            } compactTrailing: {
                let arrived = context.state.buses.filter { $0.bay != nil }.count
                let total = context.state.buses.count
                Text("\(arrived)/\(total)")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(arrived > 0 ? .green : .orange)
            } minimal: {
                let allArrived = !context.state.buses.isEmpty && context.state.buses.allSatisfy { $0.bay != nil }
                Image(systemName: allArrived ? "checkmark.circle.fill" : "bus")
                    .foregroundStyle(allArrived ? .green : .orange)
            }
            .keylineTint(context.state.buses.allSatisfy { $0.bay != nil } ? .green : .orange)
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<BusActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(context.state.buses, id: \.route) { bus in
                HStack {
                    Text(bus.route)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(.primary)
                        .frame(minWidth: 48, alignment: .leading)
                    if let bay = bus.bay {
                        Text("Bay \(bay)")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.green)
                    } else {
                        Label("Waiting", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundStyle(bus.bay != nil ? .primary : .secondary)
                    }
                    Spacer()
                }
            }
            Text("Updated \(context.state.lastUpdated, style: .time)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Live Activity", as: .content, using: BusActivityAttributes(title: "My Buses")) {
    Runshaw_Bus_WidgetLiveActivity()
} contentStates: {
    BusActivityAttributes.ContentState(
        buses: [
            .init(route: "800", bay: "A7"),
            .init(route: "961", bay: nil),
            .init(route: "819", bay: "C3")
        ],
        lastUpdated: .now
    )
}
