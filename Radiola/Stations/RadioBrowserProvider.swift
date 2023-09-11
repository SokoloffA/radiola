//
//  RadioBrowserProvider.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 06.09.2023.
//

import Foundation

class RadioBrowserProvider: StationsProvider {
    var title = ""
    var searchText = ""
    var isExactMatch = false
    private(set) var stations = StationList(title: "")
    var delegate: StationsProviderDelegate?

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

        await MainActor.run {
            delegate?.fetchDidFinished(sender: self)
        }

        let request = RadioBrowser.StationsRequest()
        request.hidebroken = true
        request.order = .votes

        let type: RadioBrowser.StationsRequest.RequestType = isExactMatch ? .bytagexact : .bytag
        let resp = try await request.get(by: type, searchterm: searchText)

        await MainActor.run {
            let sts = StationList(title: self.stations.title)
            for r in resp {
                sts.append(Station(title: r.name, url: r.url))
            }
            print("Provider done", sts.nodes.count)
            self.stations = sts
            delegate?.fetchDidFinished(sender: self)
        }
    }
}
