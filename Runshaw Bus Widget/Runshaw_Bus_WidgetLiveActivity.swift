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
                    if context.state.buses.count == 1, let bus = context.state.buses.first {
                        Text(bus.route)
                            .font(.system(.title, design: .rounded, weight: .heavy))
                            .foregroundStyle(.white)
                    } else {
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
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.buses.count == 1, let bus = context.state.buses.first {
                        if let bay = bus.bay {
                            Label("Bay \(bay)", systemImage: "checkmark.circle.fill")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .foregroundStyle(.green)
                        } else {
                            Label("Waiting", systemImage: "clock")
                                .foregroundStyle(.orange)
                        }
                    } else {
                        if let first = context.state.buses.first(where: { $0.bay != nil }) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(first.route)
                                    .font(.system(.headline, design: .rounded, weight: .heavy))
                                    .foregroundStyle(.white)
                                Text("Bay \(first.bay!)")
                                    .font(.system(.caption, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.green)
                            }
                        } else {
                            Image(systemName: "clock")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.buses.count == 1 {
                        Text("Updated \(context.state.lastUpdated, style: .time)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack {
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
                    }
                }
            } compactLeading: {
                if context.state.buses.count == 1, let bus = context.state.buses.first {
                    Text(bus.route)
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                } else {
                    Image(systemName: "bus.fill")
                        .foregroundStyle(.white)
                }
            } compactTrailing: {
                if context.state.buses.count == 1, let bus = context.state.buses.first {
                    if let bay = bus.bay {
                        Text("Bay \(bay)")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "clock")
                            .foregroundStyle(.orange)
                    }
                } else {
                    let arrived = context.state.buses.filter { $0.bay != nil }.count
                    let total = context.state.buses.count
                    Text("\(arrived)/\(total)")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(arrived > 0 ? .green : .orange)
                }
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
        if context.state.buses.count == 1, let bus = context.state.buses.first {
            // Single Bus Layout
            HStack(spacing: 14) {
                Text(bus.route)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(minWidth: 72, minHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(bus.bay != nil
                                  ? AnyShapeStyle(Color.green.gradient)
                                  : AnyShapeStyle(Color.gray.opacity(0.4)))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    if let bay = bus.bay {
                        Text("Arrived")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                        Text("Bay \(bay)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                    } else {
                        Text("Waiting for \(bus.route)")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("Updated \(context.state.lastUpdated, style: .time)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        } else {
            // Multiple Buses Layout
            VStack(alignment: .leading, spacing: 6) {
                // Limit to max 3 buses to prevent out-of-bounds errors
                ForEach(Array(context.state.buses.prefix(3)), id: \.route) { bus in
                    HStack(spacing: 12) {
                        Text(bus.route)
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(minWidth: 48, minHeight: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(bus.bay != nil
                                          ? AnyShapeStyle(Color.green.gradient)
                                          : AnyShapeStyle(Color.gray.opacity(0.4)))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            if let bay = bus.bay {
                                Text("Bay \(bay)")
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(.primary)
                            } else {
                                Text("Waiting")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
                
                HStack {
                    if context.state.buses.count > 3 {
                        Text("+ \(context.state.buses.count - 3) more")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Updated \(context.state.lastUpdated, style: .time)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview("Multiple Buses", as: .content, using: BusActivityAttributes(title: "My Buses")) {
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

#Preview("Single Bus", as: .content, using: BusActivityAttributes(title: "My Buses")) {
    Runshaw_Bus_WidgetLiveActivity()
} contentStates: {
    BusActivityAttributes.ContentState(
        buses: [
            .init(route: "800", bay: "A7")
        ],
        lastUpdated: .now
    )
}
