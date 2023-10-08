//
//  RadioBrowserProvider.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 06.09.2023.
//

import Foundation

class RadioBrowserStations: StationList, SearchableStationList {
    var fetchHandler: ((SearchableStationList) -> Void)?

    var searchOptions = SearchOptions(
        allOrderTypes: [.byVotes, .byName, .byBitrate, .byCountry]
    )

    /* ****************************************
     *
     * ****************************************/
    private func requestOrderType() -> RadioBrowser.StationsRequest.OrderType {
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
    func fetch() {
        if searchOptions.searchText.isEmpty { return }

        let request = RadioBrowser.StationsRequest()
        request.hidebroken = true
        request.order = requestOrderType()

        let type: RadioBrowser.StationsRequest.RequestType = searchOptions.isExactMatch ? .bytagexact : .bytag

        Task {
            do {
                let resp = try await request.get(by: type, searchterm: searchOptions.searchText)
                let res = StationList()

                for r in resp {
                    res.append(Station(title: r.name, url: r.url))
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
