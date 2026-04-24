//
//  ActivityManager.swift
//  Runshaw Bus
//
//  Created by Jacob on 24/04/2026.
//

import Foundation
import ActivityKit

enum ActivityManager {
    static var current: Activity<BusActivityAttributes>? {
        Activity<BusActivityAttributes>.activities.first
    }

    static var isActive: Bool { current != nil }

    // Only one activity at a time; end any existing one before starting
    static func start(routes: [String]) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, !routes.isEmpty else { return }
        await end()

        let attributes = BusActivityAttributes(title: "My Buses")
        let state = BusActivityAttributes.ContentState(
            buses: routes.map { BusActivityAttributes.BusInfo(route: $0, bay: nil) },
            lastUpdated: .now
        )
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(4 * 3600))

        do {
            _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            print("Couldn't start Live Activity: \(error)")
        }
    }

    // Rebuilds state from the routes stored in the current activity, not from FavoritesStore,
    // so the displayed set stays stable even if favorites change mid-session.
    static func update(with buses: [Bus]) async {
        guard let activity = current else { return }
        let trackedRoutes = activity.content.state.buses.map(\.route)
        let newBuses = trackedRoutes.map { route -> BusActivityAttributes.BusInfo in
            let bus = buses.first { $0.number == route }
            return BusActivityAttributes.BusInfo(route: route, bay: bus?.hasArrived == true ? bus?.bay : nil)
        }
        let newState = BusActivityAttributes.ContentState(buses: newBuses, lastUpdated: .now)
        await activity.update(ActivityContent(state: newState, staleDate: Date().addingTimeInterval(4 * 3600)))
    }

    static func end() async {
        for activity in Activity<BusActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
