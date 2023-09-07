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
    let stations = StationList(title: "")

    func fetch() async throws {
        if searchText.isEmpty {
            return
        }

        stations.removeAll()

        do {
            let request = RadioBrowser.StationsRequest()
            request.hidebroken = true
            request.order = .votes

            let res = try await request.get(bytag: searchText)
            requestDone(res)

        } catch {
            print("Request failed with error: \(error)")
        }
    }

    private func requestDone(_ resp: [RadioBrowser.Station]) {
        for r in resp {
            var s = Station(title: r.name, url: r.url)
            stations.append(s)
        }
    }
}
