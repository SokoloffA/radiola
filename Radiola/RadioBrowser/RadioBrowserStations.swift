//
//  RadioBrowserStations.swift
//  Radiola
//
//  Created by Alex Sokolov on 28.08.2023.
//

import Foundation

/* ************************************************
 * RadioBrowser.Station
 * ************************************************/
extension RadioBrowser {
    public struct Station: Decodable {
        /// A globally unique identifier for the change of the station information
        var changeuuid: String

        /// A globally unique identifier for the station
        var stationuuid: String

        /// The name of the station
        var name: String

        /// The stream URL provided by the user
        var url: String

        /// An automatically "resolved" stream URL. Things resolved are playlists (M3U/PLS/ASX...), HTTP redirects (Code 301/302).
        /// This link is especially usefull if you use this API from a platform that is not able to do a resolve on its own
        /// (e.g. JavaScript in browser) or you just don't want to invest the time in decoding playlists yourself.
        var url_resolved: String

        /// URL to the homepage of the stream, so you can direct the user to a page with more information about the stream.
        var homepage: String

        /// URL to an icon or picture that represents the stream. (PNG, JPG)
        var favicon: String

        /// multivalue, split by comma    Tags of the stream with more information about it
        var tags: [String]

        /// 2 letters, uppercase    Official countrycodes as in ISO 3166-1 alpha-2
        var countryCode: String

        /// Full name of the entity where the station is located inside the country
        var state: String

        ///  multivalue, split by comma    Languages that are spoken in this stream.
        var language: [String]

        /// multivalue, split by comma    Languages that are spoken in this stream by code ISO 639-2/B
        var languagecodes: [String]

        /// Number of votes for this station. This number is by server and only ever increases. It will never be reset to 0.
        var votes: Int

        /// Last time when the stream information was changed in the database
        var lastchangetime: Date

        /// The codec of this stream recorded at the last check.
        var codec: String

        /// number, integer, bps    The bitrate of this stream recorded at the last check.
        var bitrate: Int

        /// Mark if this stream is using HLS distribution or non-HLS.
        var hls: Bool

        /// The current online/offline state of this stream. This is a value calculated from multiple measure points in the internet. The test servers are located in different countries. It is a majority vote.
        var lastcheckok: Bool

        /// The last time when any radio-browser server checked the online state of this stream
        var lastchecktime: Date

        /// datetime, YYYY-MM-DD HH:mm:ss    The last time when the stream was checked for the online status with a positive result
        var lastcheckoktime: Date

        /// datetime, YYYY-MM-DD HH:mm:ss    The last time when this server checked the online state and the metadata of this stream
        var lastlocalchecktime: Date?

        /// datetime, YYYY-MM-DD HH:mm:ss    The time of the last click recorded for this stream
        var clicktimestamp: Date

        /// number, integer    Clicks within the last 24 hours
        var clickcount: Int

        /// number, integer    The difference of the clickcounts within the last 2 days. Posivite values mean an increase, negative a decrease of clicks.
        var clicktrend: Int

        /// number, integer    0 means no error, 1 means that there was an ssl error while connecting to the stream url.
        var ssl_error: Bool

        /// number, double    Latitude on earth where the stream is located.
        var geo_lat: Double?

        /// number, double    Longitude on earth where the stream is located.
        var geo_long: Double?

        /// bool, optional    Is true, if the stream owner does provide extended information as HTTP headers which override the information in the database.
        var has_extended_info: Bool?

        private enum CodingKeys: String, CodingKey {
            case changeuuid
            case stationuuid
            case name
            case url
            case url_resolved
            case homepage
            case favicon
            case tags
            case countrycode
            case state
            case language
            case languagecodes
            case votes
            case lastchangetime
            case lastchangetime_iso8601
            case codec
            case bitrate
            case hls
            case lastcheckok
            case lastchecktime
            case lastchecktime_iso8601
            case lastcheckoktime
            case lastcheckoktime_iso8601
            case lastlocalchecktime
            case lastlocalchecktime_iso8601
            case clicktimestamp
            case clicktimestamp_iso8601
            case clickcount
            case clicktrend
            case ssl_error
            case geo_lat
            case geo_long
            case has_extended_info
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            changeuuid = try container.decode(String.self, forKey: .changeuuid)
            stationuuid = try container.decode(String.self, forKey: .stationuuid)
            name = try container.decode(String.self, forKey: .name)
            url = try container.decode(String.self, forKey: .url)
            url_resolved = try container.decode(String.self, forKey: .url_resolved)
            homepage = try container.decode(String.self, forKey: .homepage)
            favicon = try container.decode(String.self, forKey: .favicon)
            tags = try container.decode(String.self, forKey: .tags).split(separator: ",").map { String($0) }
            countryCode = try container.decode(String.self, forKey: .countrycode)
            state = try container.decode(String.self, forKey: .state)
            language = try container.decode(String.self, forKey: .language).split(separator: ",").map { String($0) }
            languagecodes = try container.decode(String.self, forKey: .languagecodes).split(separator: ",").map { String($0) }
            votes = try container.decode(Int.self, forKey: .votes)
            lastchangetime = Date()
            codec = try container.decode(String.self, forKey: .codec)
            bitrate = try container.decode(Int.self, forKey: .bitrate)
            hls = try container.decode(Int.self, forKey: .hls) > 0
            lastcheckok = try container.decode(Int.self, forKey: .lastcheckok) > 0
            lastchecktime = try container.decode(Date.self, forKey: .lastchecktime_iso8601)
            lastcheckoktime = try container.decode(Date.self, forKey: .lastcheckoktime_iso8601)
            let s = try container.decode(String?.self, forKey: .lastlocalchecktime_iso8601)
            if s != nil && !s!.isEmpty {
                lastlocalchecktime = try container.decode(Date.self, forKey: .lastlocalchecktime_iso8601)
            }
            clicktimestamp = try container.decode(Date.self, forKey: .clicktimestamp_iso8601)
            clickcount = try container.decode(Int.self, forKey: .clickcount)
            clicktrend = try container.decode(Int.self, forKey: .clicktrend)
            ssl_error = try container.decode(Int.self, forKey: .ssl_error) > 0
            geo_lat = try container.decode(Double?.self, forKey: .geo_lat)
            geo_long = try container.decode(Double?.self, forKey: .geo_long)
            has_extended_info = try container.decode(Bool.self, forKey: .has_extended_info)
        }
    }
}

/* ************************************************
 * RadioBrowser.Stations
 * ************************************************/
extension RadioBrowser {
    enum Stations {
        /// Name of the attribute the stations result list will be sorted by
        enum Order: String {
            case name
            case url
            case homepage
            case favicon
            case tags
            case country
            case state
            case language
            case votes
            case codec
            case bitrate
            case lastcheckok
            case lastchecktime
            case clicktimestamp
            case clickcount
            case clicktrend
            case changetimestamp
            case random
        }

        enum RequestType: String {
            case byUUID
            case byName
            case byNameExact
            case byCodec
            case byCodecExact
            case byCountry
            case byCountryExact
            case byCountryCodeExact
            case byState
            case byStateExact
            case byLanguage
            case byLanguageExact
            case byTag
            case byTagExact
        }
    }
}

/* ************************************************
 * RadioBrowser.Server
 * ************************************************/
extension RadioBrowser.Server {
    // ******************************************************************
    /// A list of radio stations that match the search. The variants with "exact" will only search for perfect
    /// matches, and others will search for the station whose attribute contains the search term.
    /// - Parameter by: The type of search. The variants with "exact" will only search for perfect
    ///   matches, and others will search for the station whose attribute contains the search term.
    /// - Parameter searchTerm: Search string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(by: RadioBrowser.Stations.RequestType, searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station] {
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

        if limit != 100000 {
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }

        if hideBroken {
            queryItems.append(URLQueryItem(name: "hidebroken", value: "true"))
        }

        let path = "/json/stations/\(by.rawValue.lowercased())/\(searchTerm)"

        return try await fetch([RadioBrowser.Station].self, path: path, queryItems: queryItems)
    }

    // ******************************************************************
    /// A list of radio stations whose UUID matches the searchTerm.
    /// - Parameter searchTerm: Search UUID string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(byUUID searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station]
    {
        return try await listStations(by: .byUUID, searchTerm: searchTerm, hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }

    // ******************************************************************
    /// A list of radio stations whose name contains the searchTerm.
    /// - Parameter searchTerm: Search name string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(byname searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station]
    {
        return try await listStations(by: .byName, searchTerm: searchTerm, hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }

    // ******************************************************************
    /// A list of radio stations whose name matches the searchTerm.
    /// - Parameter searchTerm: Search name string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(bynameExact searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station]
    {
        return try await listStations(by: .byNameExact, searchTerm: searchTerm, hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }

    // ******************************************************************
    /// A list of radio stations whose codec contains the searchTerm.
    /// - Parameter searchTerm: Search codec string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(byCodec searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station]
    {
        return try await listStations(by: .byCodec, searchTerm: searchTerm, hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }

    // ******************************************************************
    /// A list of radio stations whose codec matches the searchTerm.
    /// - Parameter searchTerm: Search codec string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(byCodecExact searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station]
    {
        return try await listStations(by: .byCodecExact, searchTerm: searchTerm, hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }

    // ******************************************************************
    /// A list of radio stations whose country contains the searchTerm.
    /// - Parameter searchTerm: Search country string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(byCountry searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station]
    {
        return try await listStations(by: .byCountry, searchTerm: searchTerm, hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }

    // ******************************************************************
    /// A list of radio stations whose country matches the searchTerm.
    /// - Parameter searchTerm: Search country string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(byCountryExact searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station]
    {
        return try await listStations(by: .byCountryExact, searchTerm: searchTerm, hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }

    // ******************************************************************
    /// A list of radio stations whose country code matches the searchTerm.
    /// - Parameter searchTerm: Search country code string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(byCcountryCodeExact searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station]
    {
        return try await listStations(by: .byCountryCodeExact, searchTerm: searchTerm, hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }

    // ******************************************************************
    /// A list of radio stations whose state contains the searchTerm.
    /// - Parameter searchTerm: Search state string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(byState searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station]
    {
        return try await listStations(by: .byState, searchTerm: searchTerm, hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }

    // ******************************************************************
    /// A list of radio stations whose state matches the searchTerm.
    /// - Parameter searchTerm: Search state string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(byStateExact searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station]
    {
        return try await listStations(by: .byStateExact, searchTerm: searchTerm, hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }

    // ******************************************************************
    /// A list of radio stations whose language contains the searchTerm.
    /// - Parameter searchTerm: Search language string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(byLanguage searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station]
    {
        return try await listStations(by: .byLanguage, searchTerm: searchTerm, hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }

    // ******************************************************************
    /// A list of radio stations whose language matches the searchTerm.
    /// - Parameter searchTerm: Search language string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(byLanguageExact searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station]
    {
        return try await listStations(by: .byLanguageExact, searchTerm: searchTerm, hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }

    // ******************************************************************
    /// A list of radio stations whose tag contains the searchTerm.
    /// - Parameter searchTerm: Search tag string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(byTag searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station]
    {
        return try await listStations(by: .byTag, searchTerm: searchTerm, hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }

    // ******************************************************************
    /// A list of radio stations whose tag matches the searchTerm.
    /// - Parameter searchTerm: Search tag string
    /// - Parameter hideBroken: Do list/not list broken stations
    /// - Parameter order: Name of the attribute the result list will be sorted by.
    /// - Parameter reverse: Reverse the result list if set to true
    /// - Parameter offset: Starting value of the result list from the database. For example, if you want to do paging on the server side.
    /// - Parameter limit: Number of returned datarows (stations) starting with offset
    public func listStations(byTagExact searchTerm: String, hideBroken: Bool = true, order: RadioBrowser.Stations.Order = .name, reverse: Bool = false, offset: Int = 0, limit: Int = 100000) async throws -> [RadioBrowser.Station]
    {
        return try await listStations(by: .byTagExact, searchTerm: searchTerm, hideBroken: hideBroken, order: order, reverse: reverse, offset: offset, limit: limit)
    }
}
