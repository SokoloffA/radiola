//
//  RadioBrowserProvider.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 01.12.2023.
//

import Foundation

// MARK: - RadioBrowserProvider

class RadioBrowserProvider: InternetStationProvider {
    /* ****************************************
     *
     * ****************************************/
    @MainActor override func fetch() async {
        print("@@ \(title), \(searchText)")
        isLoading = true
        defer { isLoading = false }

        if searchText.isEmpty { return }
        print(title, id)
        print(searchType, requestType())
        let type = requestType()

        do {
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
                var s = InternetStation(title: r.name, url: r.url)
                s.codec = r.codec
                s.bitrate = r.bitrate * 1024
                s.votes = r.votes
                s.countryCode = r.countryCode
                res.append(s)
            }

            stations = res

        } catch {
            await MainActor.run {
                print(error)
                Alarm.show(title: "Couldn't download the stations from radio-browser.info", message: "\(error.localizedDescription)")
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func requestType() -> RadioBrowser.Stations.RequestType {
        switch (searchType, isExactMatch) {
            case (.byTag, true): RadioBrowser.Stations.RequestType.byTagExact
            case (.byTag, false): RadioBrowser.Stations.RequestType.byTag

            case (.byName, true): RadioBrowser.Stations.RequestType.byNameExact
            case (.byName, false): RadioBrowser.Stations.RequestType.byName

            case (.byCountry, true): RadioBrowser.Stations.RequestType.byCountryExact
            case (.byCountry, false): RadioBrowser.Stations.RequestType.byCountry
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
