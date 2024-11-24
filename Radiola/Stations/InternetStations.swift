//
//  InternetStations.swift
//  Radiola
//
//  Created by Alex Sokolov on 16.12.2023.
//

import Foundation

// MARK: - InternetStation

class InternetStation: Station, Identifiable {
    var id = UUID()
    var title: String
    var url: String
    var codec: String?
    var bitrate: Bitrate?
    var votes: Int?
    var countryCode: String?
    var isFavorite: Bool = false

    /* ****************************************
     *
     * ****************************************/
    init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}

// MARK: - InternetStationList

class InternetStationList: ObservableObject {

    let id = UUID()
    let title: String
    let icon: String

    var items = [InternetStation]()

    enum State {
        case notLoaded
        case loading
        case error
        case loaded
    }

    @Published var state = State.notLoaded

    let provider: RadioBrowserProvider

    /* ****************************************
     *
     * ****************************************/
    init(title: String, icon: String, provider: RadioBrowserProvider) {
        self.title = title
        self.icon = icon
        self.provider = provider
    }

    /* ****************************************
     *
     * ****************************************/
    func firstStation(where predicate: (Station) -> Bool) -> Station? {
        return items.first(where: predicate)
    }

    /* ****************************************
     *
     * ****************************************/
    @MainActor func fetch() async {
        state = .loading

        if !provider.canFetch() { return }

        do {
            items = try await provider.fetch()
            state = .loaded
        } catch {
            state = .error
            await MainActor.run {
                warning(error)
                Alarm.show(title: "Couldn't download the stations from radio-browser.info", message: "\(error.localizedDescription)")
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func first(byID: UUID) -> Station? {
        return firstStation { $0.id == byID }
    }
}

extension [InternetStationList] {
    func find(byId: UUID) -> InternetStationList? {
        return first { $0.id == byId }
    }
}
