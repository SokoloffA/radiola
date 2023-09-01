//
//  RadioBrowserStations.swift
//  Radiola
//
//  Created by Alex Sokolov on 28.08.2023.
//

import Foundation

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
        var countrycode: String

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
            countrycode = try container.decode(String.self, forKey: .countrycode)
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

extension RadioBrowser {
    public class StationsRequest {
        enum OrderType: String {
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

        private static let defaultOrder = OrderType.name
        private static let defaultLimit = 100000

        var order: OrderType = defaultOrder /// name of the attribute the result list will be sorted by
        var reverse: Bool = false /// reverse the result list if set to true
        var offset: Int = 0 /// starting value of the result list from the database. For example, if you want to do paging on the server side.
        var limit: Int = defaultLimit /// number of returned datarows (stations) starting with offset
        var hidebroken: Bool = false /// do list/not list broken stations

        /* ****************************************
         *
         * ****************************************/
        private func httpParamsString() -> [URLQueryItem] {
            var res = [URLQueryItem]()

            res.append(URLQueryItem(name: "order", value: order.rawValue))

            if reverse {
                res.append(URLQueryItem(name: "reverse", value: "true"))
            }

            if offset > 0 {
                res.append(URLQueryItem(name: "offset", value: "\(offset)"))
            }

            if limit != StationsRequest.defaultLimit {
                res.append(URLQueryItem(name: "limit", value: "\(limit)"))
            }

            if hidebroken {
                res.append(URLQueryItem(name: "hidebroken", value: "true"))
            }

            return res
        }

        /* ****************************************
         *
         * ****************************************/
        private func fetch(url: String) async throws -> [Station] {
            guard var url = URLComponents(string: url) else {
                throw RadioBrowserError.invalidURL
            }
            url.queryItems = httpParamsString()

            guard let url = url.url else {
                throw RadioBrowserError.invalidURL
            }

            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.iso8601

            let res = try decoder.decode([Station].self, from: data)

            return res
        }

        /* ****************************************
         *
         * ****************************************/
        public func get(byuuid searchterm: String) async throws -> [RadioBrowser.Station] {
            let url = "http://at1.api.radio-browser.info/json/stations/byuuid/\(searchterm)"
            return try await fetch(url: url)
        }

        /* ****************************************
         *
         * ****************************************/
        public func get(byname searchterm: String) async throws -> [RadioBrowser.Station] {
            let url = "http://at1.api.radio-browser.info/json/stations/byname/\(searchterm)"
            return try await fetch(url: url)
        }

        /* ****************************************
         *
         * ****************************************/
        public func get(bynameexact searchterm: String) async throws -> [RadioBrowser.Station] {
            let url = "http://at1.api.radio-browser.info/json/stations/bynameexact/\(searchterm)"
            return try await fetch(url: url)
        }

        /* ****************************************
         *
         * ****************************************/
        public func get(bycodec searchterm: String) async throws -> [RadioBrowser.Station] {
            let url = "http://at1.api.radio-browser.info/json/stations/bycodec/\(searchterm)"
            return try await fetch(url: url)
        }

        /* ****************************************
         *
         * ****************************************/
        public func get(bycodecexact searchterm: String) async throws -> [RadioBrowser.Station] {
            let url = "http://at1.api.radio-browser.info/json/stations/bycodecexact/\(searchterm)"
            return try await fetch(url: url)
        }

        /* ****************************************
         *
         * ****************************************/
        public func get(bycountry searchterm: String) async throws -> [RadioBrowser.Station] {
            let url = "http://at1.api.radio-browser.info/json/stations/bycountry/\(searchterm)"
            return try await fetch(url: url)
        }

        /* ****************************************
         *
         * ****************************************/
        public func get(bycountryexact searchterm: String) async throws -> [RadioBrowser.Station] {
            let url = "http://at1.api.radio-browser.info/json/stations/bycountryexact/\(searchterm)"
            return try await fetch(url: url)
        }

        /* ****************************************
         *
         * ****************************************/
        public func get(bycountrycodeexact searchterm: String) async throws -> [RadioBrowser.Station] {
            let url = "http://at1.api.radio-browser.info/json/stations/bycountrycodeexact/\(searchterm)"
            return try await fetch(url: url)
        }

        /* ****************************************
         *
         * ****************************************/
        public func get(bystate searchterm: String) async throws -> [RadioBrowser.Station] {
            let url = "http://at1.api.radio-browser.info/json/stations/bystate/\(searchterm)"
            return try await fetch(url: url)
        }

        /* ****************************************
         *
         * ****************************************/
        public func get(bystateexact searchterm: String) async throws -> [RadioBrowser.Station] {
            let url = "http://at1.api.radio-browser.info/json/stations/bystateexact/\(searchterm)"
            return try await fetch(url: url)
        }

        /* ****************************************
         *
         * ****************************************/
        public func get(bylanguage searchterm: String) async throws -> [RadioBrowser.Station] {
            let url = "http://at1.api.radio-browser.info/json/stations/bylanguage/\(searchterm)"
            return try await fetch(url: url)
        }

        /* ****************************************
         *
         * ****************************************/
        public func get(bylanguageexact searchterm: String) async throws -> [RadioBrowser.Station] {
            let url = "http://at1.api.radio-browser.info/json/stations/bylanguageexact/\(searchterm)"
            return try await fetch(url: url)
        }

        /* ****************************************
         *
         * ****************************************/
        public func get(bytag searchterm: String) async throws -> [RadioBrowser.Station] {
            let url = "http://at1.api.radio-browser.info/json/stations/bytag/\(searchterm.lowercased())"
            return try await fetch(url: url)
        }

        /* ****************************************
         *
         * ****************************************/
        public func get(bytagexact searchterm: String) async throws -> [RadioBrowser.Station] {
            let url = "http://at1.api.radio-browser.info/json/stations/bytagexact/\(searchterm)"
            return try await fetch(url: url)
        }
    }
}
