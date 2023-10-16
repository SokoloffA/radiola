//
//  RadioBrowserProvider.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 06.09.2023.
//

import Foundation

class RadioBrowserStationsByName: RadioBrowserStations {
    override func searchType() -> RadioBrowser.Stations.RequestType { .byName }
}

class RadioBrowserStationsByTag: RadioBrowserStations {
    override func searchType() -> RadioBrowser.Stations.RequestType { .byTag }
}

class RadioBrowserStationsByCountry: RadioBrowserStations {
    override func searchType() -> RadioBrowser.Stations.RequestType { .byCountry }
}

/* ********************************************
 *
 * ********************************************/
class RadioBrowserStations: StationList, SearchableStationList {
    internal func searchType() -> RadioBrowser.Stations.RequestType { .byTag }
    public let settingsPath: String?

    var fetchHandler: ((SearchableStationList) -> Void)?

    var searchOptions = SearchOptions(
        allOrderTypes: [.byVotes, .byName, .byBitrate, .byCountry]
    )

    /* ****************************************
     *
     * ****************************************/
    init(title: String, settingsPath: String?) {
        self.settingsPath = settingsPath
        super.init(title: title)
        loadSettings()
    }

    /* ****************************************
     *
     * ****************************************/
    private func orderToStr(_ order: SearchOptions.Order) -> String {
        switch order {
            case .byName: return "byName"
            case .byVotes: return "byVotes"
            case .byCountry: return "byCountry"
            case .byBitrate: return "byBitrate"
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func strToOrder(_ str: String?, default defaultValue: SearchOptions.Order) -> SearchOptions.Order {
        switch str {
            case "byName": return .byName
            case "byVotes": return .byVotes
            case "byCountry": return .byCountry
            case "byBitrate": return .byBitrate
            default: return defaultValue
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func loadSettings() {
        guard let settingsPath = settingsPath else { return }
        let data = UserDefaults.standard

        searchOptions.searchText = data.string(forKey: settingsPath + "/search") ?? ""
        searchOptions.isExactMatch = data.bool(forKey: settingsPath + "/exact")
        searchOptions.order = strToOrder(data.string(forKey: settingsPath + "/order"), default: .byVotes)
    }

    /* ****************************************
     *
     * ****************************************/
    private func saveSettings() {
        guard let settingsPath = settingsPath else { return }
        let data = UserDefaults.standard

        data.set(searchOptions.searchText, forKey: settingsPath + "/search")
        data.set(searchOptions.isExactMatch, forKey: settingsPath + "/exact")
        data.set(orderToStr(searchOptions.order), forKey: settingsPath + "/order")
    }

    /* ****************************************
     *
     * ****************************************/
    private func requestOrderType() -> RadioBrowser.Stations.Order {
        switch searchOptions.order {
            case .byName: return .name
            case .byVotes: return .votes
            case .byCountry: return .country
            case .byBitrate: return .bitrate
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func requestType() -> RadioBrowser.Stations.RequestType {
        switch searchType() {
            case .byUUID: return .byUUID
            case .byName, .byNameExact: return searchOptions.isExactMatch ? .byNameExact : .byName
            case .byCodec, .byCodecExact: return searchOptions.isExactMatch ? .byCodecExact : .byCodec
            case .byCountry, .byCountryExact: return searchOptions.isExactMatch ? .byCountryExact : .byCountry
            case .byCountryCodeExact: return .byCountryCodeExact
            case .byState, .byStateExact: return searchOptions.isExactMatch ? .byStateExact : .byState
            case .byLanguage, .byLanguageExact: return searchOptions.isExactMatch ? .byLanguageExact : .byLanguage
            case .byTag, .byTagExact: return searchOptions.isExactMatch ? .byTagExact : .byTag
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func fetch() {
        if searchOptions.searchText.isEmpty { return }

        let type = requestType()
        saveSettings()

        Task {
            do {
                let server = try await RadioBrowser.getFastestServer()

                var reverse = false
                let order = requestOrderType()
                switch order {
                    case .bitrate: reverse = true
                    case .votes: reverse = true
                    default: reverse = false
                }

                let resp = try await server.listStations(by: type, searchTerm: searchOptions.searchText, order: order, reverse: reverse, limit: 1000)
                let res = StationList()

                for r in resp {
                    let s = Station(title: r.name, url: r.url)
                    s.bitrate = r.bitrate * 1024
                    s.votes = r.votes
                    s.countryCode = r.countryCode
                    res.append(s)
                }
                await MainActor.run {
                    self.nodes = res.nodes
                    fetchHandler?(self)
                }
            } catch {
                errorOccurred(object: self, message: error.localizedDescription)
            }
        }
    }
}
