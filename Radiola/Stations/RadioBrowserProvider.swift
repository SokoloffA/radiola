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
    let stations = StationList(title: "")

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
        print(#function, #line)
        if searchText.isEmpty {
            return
        }
        print(#function, #line)
        let request = RadioBrowser.StationsRequest()
        request.hidebroken = true
        request.order = .votes
        print(#function, #line)

        var type: RadioBrowser.StationsRequest.RequestType = isExactMatch ? .bytagexact : .bytag
        let resp = try await request.get(by: type, searchterm: searchText)
        print(#function, #line, resp.count)
        await MainActor.run {
            print(#function, Unmanaged.passUnretained(stations).toOpaque())
            stations.removeAll()
            for r in resp {
                stations.append(Station(title: r.name, url: r.url))
            }
            print(stations.nodes.count)
        }
    }
}
