//
//  ApiService.swift
//  Runshaw Bus
//
//  Created by Jacob on 24/04/2026.
//

import Foundation
import SwiftUI
import SwiftSoup

struct ApiService {
    private let PAGE_URL = URL(string: "https://webservices.runshaw.ac.uk/bus/busdepartures.aspx")!
    private var session: URLSession = URLSession.shared
    
    func getData() async -> [Bus]? {
        do {
            let (data, response) = try await session.data(from: PAGE_URL)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                handleServerError(response)
                return nil
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                handleServerError(httpResponse)
                return nil
            }
            guard let html = String(data: data, encoding: .utf8) else {
                handleClientError(URLError(.cannotDecodeContentData))
                return nil
            }
            
            return try parseHTML(html)
        } catch is CancellationError {
            return nil
        } catch let urlError as URLError where urlError.code == .cancelled {
            return nil
        } catch {
            handleClientError(error)
            return nil
        }
    }
    
    func parseHTML(_ html: String) throws -> [Bus] {
        let doc = try SwiftSoup.parse(html)
        let rows = try doc.select("table#grdAll tbody tr")
        
        return try rows.enumerated().compactMap { index, row in
            let cells = try row.select("td")
            guard cells.size() >= 3 else { return nil }
            
            let number = try cells.get(0).text().trimmingCharacters(in: .whitespaces)
            let bay = try cells.get(2).text().trimmingCharacters(in: .whitespaces)
            
            guard !number.isEmpty else { return nil }
            
            return Bus(id: index, number: number, bay: bay.isEmpty ? "TBC": bay)
        }
    }
    
    // MARK: - Error Handling
    
    private func handleClientError(_ error: Error, url: URL? = nil) {
        if let url = url {
            print("Client error fetching \(url): \(error.localizedDescription)")
        } else {
            print("Client error: \(error.localizedDescription)")
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet: print("No internet connection.")
            case .timedOut: print("The request timed out.")
            case .cannotFindHost,
                    .cannotConnectToHost: print("Could not reach the server.")
            case .cannotDecodeContentData: print("Unexpected content type in response.")
            case .badURL: print("The URL is malformed.")
            default: print("Unexpected URL error: \(urlError.code)")
            }
        }
    }
    
    private func handleServerError(_ response: URLResponse?) {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Server error: invalid or missing response.")
            return
        }
        switch httpResponse.statusCode {
        case 400: print("Server error 400: Bad request.")
        case 401, 403: print("Server error \(httpResponse.statusCode): Access denied.")
        case 404: print("Server error 404: Resource not found.")
        case 500...599: print("Server error \(httpResponse.statusCode): Server-side failure.")
        default: print("Server error \(httpResponse.statusCode): Unexpected status code.")
        }
    }
}
