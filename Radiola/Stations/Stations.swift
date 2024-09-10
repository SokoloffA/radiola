//
//  Stations.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 01.12.2023.
//

import Cocoa

// MARK: - StationItem

let StationItemPasteboardType = NSPasteboard.PasteboardType(rawValue: "Station.row")

protocol StationItem: AnyObject {
    var id: UUID { get }
    var title: String { get set }
}

// MARK: - Station

protocol Station: StationItem {
    var id: UUID { get }
    var title: String { get set }
    var url: String { get set }
    var isFavorite: Bool { get set }
}

extension Station {
    /* ****************************************
     *
     * ****************************************/
    func fill(from: Station) {
        title = from.title
        url = from.url
        isFavorite = from.isFavorite
    }
}

// MARK: - StationGroup

protocol StationGroup: StationItem {
    var id: UUID { get }
    var title: String { get set }
    var items: [StationItem] { get set }
}

extension StationGroup {
    /* ****************************************
     *
     * ****************************************/
    func fill(from: StationGroup) {
        title = from.title
    }

    /* ****************************************
     *
     * ****************************************/
    func append(_ item: StationItem) {
        items.append(item)
    }

    /* ****************************************
     *
     * ****************************************/
    func insert(_ item: StationItem, afterId: UUID) {
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
