//
//  InternetStations.swift
//  Radiola
//
//  Created by Alex Sokolov on 16.12.2023.
//

import Foundation

// MARK: - InternetStation

struct InternetStation: Station, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var url: String
    var codec: String?
    var bitrate: Bitrate?
    var votes: Int?
    var countryCode: String?

    /* ****************************************
     *
     * ****************************************/
    init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}

// MARK: - InternetStationList

class InternetStationList: ObservableObject, StationList {
    let id = UUID()
    let title: String
    let icon: String
    let help: String?

    @Published var stations = [InternetStation]()

    @Published var isLoading = false

    let provider: RadioBrowserProvider

    /* ****************************************
     *
     * ****************************************/
    init(title: String, icon: String, help: String? = nil, provider: RadioBrowserProvider) {
        self.title = title
        self.icon = icon
        self.help = help
        self.provider = provider
    }

    /* ****************************************
     *
     * ****************************************/
    func first(where predicate: (Station) -> Bool) -> Station? {
        return stations.first(where: predicate)
    }

    /* ****************************************
     *
     * ****************************************/
    @MainActor func fetch() async {
        isLoading = true
        defer { isLoading = false }

        if !provider.canFetch() { return }

        do {
            stations = try await provider.fetch()
        } catch {
            await MainActor.run {
                warning(error)
                Alarm.show(title: "Couldn't download the stations from radio-browser.info", message: "\(error.localizedDescription)")
            }
        }
    }
}