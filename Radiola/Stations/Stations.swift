//
//  Stations.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 01.12.2023.
//

import Foundation

// MARK: - Station

protocol Station {
    var id: UUID { get }
    var title: String { get set }
    var url: String { get set }
}

// MARK: - LocalStation

struct LocalStation: Station {
    var id = UUID()
    var title: String
    var url: String
    var isFavorite: Bool = false

    /* ****************************************
     *
     * ****************************************/
    init(title: String, url: String, isFavorite: Bool = false) {
        self.title = title
        self.url = url
        self.isFavorite = isFavorite
    }
}

// MARK: - LocalStationGroup

class LocalStationGroup {
    var title: String
    var items: [Item] = []

    enum Item {
        case station(station: LocalStation)
        case group(group: LocalStationGroup)
    }

    /* ****************************************
     *
     * ****************************************/
    init(title: String, items: [Item]) {
        self.title = title
        self.items = items
    }
}

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

// MARK: - InternetStationProvider

class InternetStationProvider: ObservableObject {
    let id = UUID()
    let title: String
    let icon: String
    let help: String?
    @Published var stations: [InternetStation] = []
    @Published var isLoading = false

    // search options
    let searchType: SearchType
    var searchText: String = ""
    var isExactMatch: Bool = false { didSet { print("isExactMatch: \(isExactMatch)") }}
    var order: Order = .byName

    enum SearchType: String {
        case byTag
        case byName
        case byCountry
    }

    enum Order: Int {
        case byName
        case byVotes
        case byCountry
        case byBitrate
    }

    /* ****************************************
     *
     * ****************************************/
    init(type: SearchType, title: String, icon: String, help: String? = nil) {
        self.searchType = type
        self.title = title
        self.icon = icon
        self.help = help
    }

    /* ****************************************
     *
     * ****************************************/
    func fetch() async {
    }
}

// MARK: - LocalStationProvider

class LocalStationProvider: ObservableObject {
    let id = UUID()
    let title: String
    let icon: String
    let help: String?

    //  var stations: [LocalStation] = []

    init(title: String, icon: String, help: String?) {
        self.title = title
        self.icon = icon
        self.help = help
    }
}
