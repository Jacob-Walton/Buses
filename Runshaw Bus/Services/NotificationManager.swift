//
//  NotificationManager.swift
//  Runshaw Bus
//
//  Created by Jacob on 24/04/2026.
//

import UserNotifications

enum NotificationManager {
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func notifyArrivals(_ arrivals: [(route: String, bay: String)]) async throws {
        guard !arrivals.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        if arrivals.count == 1 {
            let a = arrivals[0]
            content.title = "Bus \(a.route) has arrived"
            content.body = "Head to Bay \(a.bay)."
        } else {
            let routes = arrivals.map(\.route).sorted().joined(separator: ", ")
            let details = arrivals
                .sorted { $0.route < $1.route }
                .map { "\($0.route) - Bay \($0.bay)" }
                .joined(separator: "\n")
            content.title = "\(arrivals.count) buses have arrived"
            content.subtitle = routes
            content.body = details
        }

        let request = UNNotificationRequest(
            identifier: "bus-arrival-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        try await UNUserNotificationCenter.current().add(request)
    }
}
