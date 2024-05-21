//
//  LocalStations.swift
//  Radiola
//
//  Created by Alex Sokolov on 10.12.2023.
//

import Foundation

// MARK: - LocalStation

class LocalStation: ObservableObject, Station {
    var id = UUID()
    @Published var title: String
    @Published var url: String
    @Published var isFavorite: Bool
    weak var parent: LocalStationGroup?

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

class LocalStationGroup: ObservableObject {
    let id = UUID()
    var title: String
    var items: [Item] = [] {
        didSet {
            for i in items.indices {
                items[i].parent = self
            }
        }
    }

    weak var parent: LocalStationGroup?

    typealias Item = LocalStationList.Item

    /* ****************************************
     *
     * ****************************************/
    init(title: String, items: [Item] = []) {
        self.title = title
        self.items = items
    }

    /* ****************************************
     *
     * ****************************************/
    func append(_ item: Item) {
        items.append(item)
    }

    /* ****************************************
     *
     * ****************************************/
    func append(_ station: LocalStation) {
        items.append(Item.station(station: station))
    }

    /* ****************************************
     *
     * ****************************************/
    func append(_ group: LocalStationGroup) {
        items.append(Item.group(group: group))
    }

    /* ****************************************
     *
     * ****************************************/
    func insert(_ item: Item, afterId: UUID) {
        let index = items.firstIndex { $0.id == afterId }

        if let index = index {
            if index < items.count - 1 {
                items.insert(item, at: index + 1)
            } else {
                append(item)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func index(_ itemId: UUID) -> Int? {
        return items.firstIndex { $0.id == itemId }
    }
}

// MARK: - LocalStationList.Item

extension LocalStationList {
    enum Item: Identifiable {
        case station(station: LocalStation)
        case group(group: LocalStationGroup)

        /* ****************************************
         *
         * ****************************************/
        var id: UUID {
            switch self {
                case let .station(station: station): return station.id
                case let .group(group: group): return group.id
            }
        }

        /* ****************************************
         *
         * ****************************************/
        var title: String {
            switch self {
                case let .station(station: station): return station.title
                case let .group(group: group): return group.title
            }
        }

        /* ****************************************
         *
         * ****************************************/
        var items: [Item]? {
            switch self {
                case .station(_: _): return nil
                case let .group(group: group): return group.items
            }
        }

        /* ****************************************
         *
         * ****************************************/
        var parent: LocalStationGroup? {
            get {
                switch self {
                    case let .station(station: station): return station.parent
                    case let .group(group: group): return group.parent
                }
            }

            set {
                switch self {
                    case let .station(station: station): return station.parent = newValue
                    case let .group(group: group): return group.parent = newValue
                }
            }
        }

        /* ****************************************
         *
         * ****************************************/
        var isStation: Bool {
            switch self {
                case .station: return true
                case .group: return false
            }
        }

        /* ****************************************
         *
         * ****************************************/
        var isGroup: Bool {
            switch self {
                case .station: return false
                case .group: return true
            }
        }
    } // Item
}
