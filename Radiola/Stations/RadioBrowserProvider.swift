//
//  RadioBrowserProvider.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 06.09.2023.
//

import Foundation

class RadioBrowserStations: StationList, SearchableStationList {
    private let searchType: RadioBrowser.StationsRequest.RequestType

    var fetchHandler: ((SearchableStationList) -> Void)?

    var searchOptions = SearchOptions(
        allOrderTypes: [.byVotes, .byName, .byBitrate, .byCountry]
    )

    /* ****************************************
     *
     * ****************************************/
    init(title: String, searchType: RadioBrowser.StationsRequest.RequestType) {
        self.searchType = searchType
        super.init(title: title)
    }

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
    private func requestType() -> RadioBrowser.StationsRequest.RequestType {
        switch searchType {
            case .byuuid: return .byuuid
            case .byname, .bynameexact: return searchOptions.isExactMatch ? .bynameexact : .byname
            case .bycodec, .bycodecexact: return searchOptions.isExactMatch ? .bycodecexact : .bycodec
            case .bycountry, .bycountryexact: return searchOptions.isExactMatch ? .bycountryexact : .bycountry
            case .bycountrycodeexact: return .bycountrycodeexact
            case .bystate, .bystateexact: return searchOptions.isExactMatch ? .bystateexact : .bystate
            case .bylanguage, .bylanguageexact: return searchOptions.isExactMatch ? .bylanguageexact : .bylanguage
            case .bytag, .bytagexact: return searchOptions.isExactMatch ? .bytagexact : .bytag
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

        let type = requestType()

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
