//
//  RadioBrowserProvider.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 06.09.2023.
//

import Foundation

extension SearchOrder {
    static let byName = SearchOrder(rawValue: "sort by name")
    static let byVotes = SearchOrder(rawValue: "sort by votes")
}

class RadioBrowserProvider: SearchProvider {
    var title = ""
    var searchText = ""
    var isExactMatch = false
    let stations = StationList(title: "")

    let allOrderTypes: [SearchOrder] = [.byVotes, .byName]
    var order = SearchOrder.byVotes

    /* ****************************************
     *
     * ****************************************/
    init(title: String) {
        self.title = title
    }

    /* ****************************************
     *
     * ****************************************/
    func fetch() async throws {
        if searchText.isEmpty {
            return
        }

        let request = RadioBrowser.StationsRequest()
        request.hidebroken = true
        request.order = .votes

        let type: RadioBrowser.StationsRequest.RequestType = isExactMatch ? .bytagexact : .bytag
        let resp = try await request.get(by: type, searchterm: searchText)
        await MainActor.run {
            stations.removeAll()
            for r in resp {
                stations.append(Station(title: r.name, url: r.url))
            }
            print(stations.nodes.count)
        }
    }
}
