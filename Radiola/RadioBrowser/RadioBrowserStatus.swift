//
//  RadioBrowserStatus.swift
//  Radiola
//
//  Created by Alex Sokolov on 04.12.2023.
//

import Foundation

// MARK: - RadioBrowser.Tag

extension RadioBrowser {
    public struct Status: Decodable {
        var supported_version: Int
        var software_version: String
        var status: String
        var stations: Int
        var stations_broken: Int
        var tags: Int
        var clicks_last_hour: Int
        var clicks_last_day: Int
        var languages: Int
        var countries: Int

        static let statusOK = "OK"
    }
}

extension RadioBrowser.Server {
    public func stats() async throws -> RadioBrowser.Status {
        let path = "/json/stats"
        return try await fetch(RadioBrowser.Status.self, path: path, queryItems: [])
    }
}
