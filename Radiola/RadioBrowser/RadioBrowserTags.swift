//
//  Tags.swift
//
//
//  Created by Alex Sokolov on 27.08.2023.
//

import Cocoa

extension RadioBrowser {
    public struct Tag: Decodable {
        var name: String
        var stationcount: Int
    }
}

extension RadioBrowser {
    public class TagRequest {
        enum OrderType {
            case name
            case stationcount
        }

        var order: OrderType = .name /// name of the attribute the result list will be sorted by
        var reverse: Bool = false /// reverse the result list if set to true
        var hidebroken: Bool = false /// do not count broken stations
        var offset: Int = 0 /// starting value of the result list from the database. For example, if you want to do paging on the server side.
        var limit: Int = 100000 /// number of returned datarows (stations) starting with offset

        var server: String = ""

        /* ****************************************
         *
         * ****************************************/
        public func get() async throws -> [Tag] {
            guard let url = URL(string: "http://at1.api.radio-browser.info/json/tags") else {
                throw  RadioBrowserError.invalidURL
            }

            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode([Tag].self, from: data)
        }
    }
}
