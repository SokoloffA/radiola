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

protocol StationList: Identifiable {
    var title: String { get }
    var icon: String { get }
    var help: String? { get }

    func first(where: (Station) -> Bool) -> Station?
}

extension StationList {
    /* ****************************************
     *
     * ****************************************/
    func first(byUrl: String) -> Station? {
        return first { $0.url == byUrl }
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
    @Published var searchText: String = ""
    @Published var isExactMatch: Bool = false
    @Published var order: Order = .byName

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
        searchType = type
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
