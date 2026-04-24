//
//  Bus.swift
//  Runshaw Bus
//
//  Created by Jacob on 24/04/2026.
//

struct Bus: Identifiable, Equatable, Codable {
    let id: Int
    let number: String
    let bay: String
    var hasArrived: Bool { bay != "TBC" }
}
