//
//  Tags.swift
//
//
//  Created by Alex Sokolov on 27.08.2023.
//

import Cocoa

// MARK: - RadioBrowser.Tag

extension RadioBrowser {
    public struct Tag: Decodable {
        var name: String
        var stationcount: Int
    }
}

/* ************************************************
 * RadioBrowser.Stations
 * ************************************************/
extension RadioBrowser {
    enum Tags {
        enum Order: String {
            case name
            case stationCount
        }
    }
}

/* ************************************************
 * RadioBrowser.Server
 * ************************************************/
extension RadioBrowser.Server {
    // ******************************************************************
    /// List of tags
    ///  A list of all tags in the database. If a filter is given, it will only return
    ///  the ones containing the filter as substring
    /// - Parameter searchTerm: Search string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listTags(searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Tags.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100_000) async throws -> [RadioBrowser.Tag] {
        var queryItems = [URLQueryItem]()

        if order != .name {
            queryItems.append(URLQueryItem(name: "order", value: order.rawValue.lowercased()))
        }

        if reverse {
            queryItems.append(URLQueryItem(name: "reverse", value: "true"))
        }

        if offset != 0 {
            queryItems.append(URLQueryItem(name: "offset", value: "\(offset)"))
        }

        if limit != 100_000 {
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }

        if hideBroken {
            queryItems.append(URLQueryItem(name: "hidebroken", value: "true"))
        }

        let path = "/json/tags\(searchTerm)"

        return try await fetch([RadioBrowser.Tag].self, path: path, queryItems: queryItems)
    }

    // ******************************************************************
    /// List of tags
    ///  A list of all tags in the database. If a filter is given, it will only return
    ///  the ones containing the filter as substring
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listTags(hideBroken: Bool = true, order: RadioBrowser.Tags.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100_000) async throws -> [RadioBrowser.Tag] {
        return try await listTags(searchTerm: "", hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }
}
