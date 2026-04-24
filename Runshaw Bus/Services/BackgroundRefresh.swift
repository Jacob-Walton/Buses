//
//  BackgroundRefresh.swift
//  Runshaw Bus
//
//  Created by Jacob on 24/04/2026.
//

import Foundation
import BackgroundTasks


enum BackgroundRefresh {
    static let taskIdentifier = "com.konpeki.Runshaw-Bus.refresh"

    static func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            guard let task = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handleRefresh(task: task)
        }
    }

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = nextCheckDate()

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Couldn't schedule background refresh: \(error)")
        }
    }

    // Returns the earliest date the next task should run.
    // Schedules 2 min ahead when inside the window, today at 15:00 if the window
    // hasn't opened yet, otherwise 15:00 on the next weekday.
    private static func nextCheckDate() -> Date {
        let cal = Calendar.current
        let now = Date()
        let in2 = now.addingTimeInterval(2 * 60)

        if isInWindow(in2) { return in2 }

        // Today is a weekday but window hasn't opened yet
        let weekday = cal.component(.weekday, from: now)
        if (2...6).contains(weekday),
           let todayStart = cal.date(bySettingHour: 15, minute: 0, second: 0, of: now),
           todayStart > now {
            return todayStart
        }

        var candidate = now
        for _ in 0..<7 {
            candidate = cal.date(byAdding: .day, value: 1, to: candidate) ?? candidate
            if (2...6).contains(cal.component(.weekday, from: candidate)) {
                return cal.date(bySettingHour: 15, minute: 0, second: 0, of: candidate) ?? in2
            }
        }
        return in2
    }

    // Active window: Mon-Fri 15:00-16:30 (school pickup)
    static func isInWindow(_ date: Date) -> Bool {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        guard (2...6).contains(weekday) else { return false }

        let c = cal.dateComponents([.hour, .minute], from: date)
        guard let h = c.hour, let m = c.minute else { return false }
        let mins = h * 60 + m
        return (15*60 ... 16*60 + 30).contains(mins)
    }

    private static func handleRefresh(task: BGAppRefreshTask) {
        // Schedule the next task before doing any work so it's never missed
        schedule()

        let work = Task {
            await performCheck()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            work.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    private static func performCheck() async {
        guard shouldCheckNow() else { return }

        let favorites = FavoritesStore()
        guard !favorites.favorites.isEmpty else { return }

        // Skip routes already notified today to avoid duplicate alerts
        let pending = favorites.favorites.filter { !favorites.hasNotifiedToday(route: $0) }
        guard !pending.isEmpty else { return }

        let api = ApiService()
        guard let buses = await api.getData() else { return }

        let arrivals = buses.filter { pending.contains($0.number) && $0.hasArrived }
        guard !arrivals.isEmpty else { return }

        let payload = arrivals.map { (route: $0.number, bay: $0.bay) }
        do {
            try await NotificationManager.notifyArrivals(payload)
            // Only mark notified after a confirmed send; if this throws we retry next cycle
            for bus in arrivals {
                favorites.markNotified(route: bus.number)
            }
        } catch {
            // will retry next cycle
        }
    }

    private static func shouldCheckNow() -> Bool {
        isInWindow(Date())
    }
}
