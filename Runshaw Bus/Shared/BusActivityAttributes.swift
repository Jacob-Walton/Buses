//
//  BusActivityAttributes.swift
//  Runshaw Bus
//
//  Created by Jacob on 24/04/2026.
//

import ActivityKit
import Foundation

struct BusActivityAttributes: ActivityAttributes {
    struct BusInfo: Codable, Hashable {
        let route: String
        let bay: String?
    }

    struct ContentState: Codable, Hashable {
        var buses: [BusInfo]
        var lastUpdated: Date
    }

    let title: String
}
