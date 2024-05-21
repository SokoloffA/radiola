//
//  LocalStations.swift
//  Radiola
//
//  Created by Alex Sokolov on 10.12.2023.
//

import Foundation

// MARK: - LocalStationItem

class LocalStationItem {
    var id = UUID()
    var title: String
    weak var parent: LocalStationGroup?

    /* ****************************************
     *
     * ****************************************/
    init(title: String) {
        self.title = title
    }

    /* ****************************************
     *
     * ****************************************/
    var path: [String] {
        var res: [String] = [title]

        var p = parent
        while p != nil {
            res.insert(p!.title, at: 0)
            p = p?.parent
        }

        res.remove(at: 0)
        return res
    }
}

// MARK: - LocalStation

class LocalStation: LocalStationItem, ObservableObject, Station {
    @Published var url: String
    @Published var isFavorite: Bool

    /* ****************************************
     *
     * ****************************************/
    init(title: String, url: String, isFavorite: Bool = false) {
        self.url = url
        self.isFavorite = isFavorite
        super.init(title: title)
    }
}

// MARK: - LocalStationGroup

class LocalStationGroup: LocalStationItem, ObservableObject {
    var items: [LocalStationItem] = [] {
        didSet {
            for i in items.indices {
                items[i].parent = self
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    init(title: String, items: [LocalStationItem] = []) {
        self.items = items
        super.init(title: title)
    }

    /* ****************************************
     *
     * ****************************************/
    func append(_ item: LocalStationItem) {
        items.append(item)
    }

    /* ****************************************
     *
     * ****************************************/
    func insert(_ item: LocalStationItem, afterId: UUID) {
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
