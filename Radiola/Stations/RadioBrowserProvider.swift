//
//  RadioBrowserProvider.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 01.12.2023.
//

import Foundation

// MARK: - RadioBrowserProvider

class RadioBrowserProvider: ObservableObject {
    // search options
    let searchType: SearchType
    @Published var searchText: String = ""
    @Published var isExactMatch: Bool = false
    @Published var order: Order = .byVotes

    enum SearchType: String {
        case byTag
        case byName
        case byCountry
    }

    enum Order: Int {
        case byName
        case byVotes
        case byCountry
        case byBitrate
    }

    /* ****************************************
     *
     * ****************************************/
    init(_ searchType: SearchType) {
        self.searchType = searchType
    }

    /* ****************************************
     *
     * ****************************************/
    func canFetch() -> Bool {
        return !searchText.isEmpty
    }

    /* ****************************************
     *
     * ****************************************/
    func fetch() async throws -> [InternetStation] {
        if !canFetch() { return [] }

        let type = requestType()
        let server = try await RadioBrowser.getFastestServer()

        var reverse = false
        let order = requestOrderType()
        switch order {
            case .bitrate: reverse = true
            case .votes: reverse = true
            default: reverse = false
        }

        let resp = try await server.listStations(by: type, searchTerm: searchText, order: order, reverse: reverse, limit: 1000)
        var res = [InternetStation]()

        for r in resp {
            let title = r.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if title == "" {
                break
            }

            let s = InternetStation(title: title, url: r.url)
            s.codec = r.codec
            s.bitrate = r.bitrate * 1024
            s.votes = r.votes
            s.countryCode = r.countryCode
            s.homepageUrl = r.homepage
            s.iconUrl = r.favicon
            res.append(s)
        }

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    private func requestType() -> RadioBrowser.Stations.RequestType {
        switch (searchType, isExactMatch) {
            case (.byTag, true): return RadioBrowser.Stations.RequestType.byTagExact
            case (.byTag, false): return RadioBrowser.Stations.RequestType.byTag

            case (.byName, true): return RadioBrowser.Stations.RequestType.byNameExact
            case (.byName, false): return RadioBrowser.Stations.RequestType.byName

            case (.byCountry, true): return RadioBrowser.Stations.RequestType.byCountryExact
            case (.byCountry, false): return RadioBrowser.Stations.RequestType.byCountry
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func requestOrderType() -> RadioBrowser.Stations.Order {
        switch order {
            case .byName: return .name
            case .byVotes: return .votes
            case .byCountry: return .country
            case .byBitrate: return .bitrate
        }
    }
}
