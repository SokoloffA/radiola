//
//  StationList.swift
//  Radiola
//
//  Created by Alex Sokolov on 25.08.2024.
//

import Foundation

// MARK: - StationList

protocol StationList: StationGroup {
    var id: UUID { get }
    var icon: String { get }
    var items: [StationItem] { get set }

    func createStation(title: String, url: String) -> Station
    func createGroup(title: String) -> StationGroup

    func load() throws
    func save() throws
}

extension StationList {
    /* ****************************************
     *
     * ****************************************/
    func trySave() {
        do {
            try save()
        } catch {
            warning("Sorry, we couldn't load iCloud stations.", error)
            Alarm.show(title: "Sorry, we couldn't load iCloud stations.", message: error.localizedDescription)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func firstStation(byURL: String) -> Station? {
        return firstStation { $0.url == byURL }
    }

    /* ****************************************
     *
     * ****************************************/
    func firstStation(byID: UUID) -> Station? {
        return firstStation { $0.id == byID }
    }

    /* ****************************************
     *
     * ****************************************/
    func firstGroup(byID: UUID) -> StationGroup? {
        return firstGroup { $0.id == byID }
    }

    /* ****************************************
     *
     * ****************************************/
    func add(_ station: Station) {
        let new = createStation(title: station.title, url: station.url)
        new.fill(from: station)
        items.append(new)
    }

    /* ****************************************
     *
     * ****************************************/
    func add(_ group: StationGroup) {
        func addGroup(src: StationGroup, parent: StationGroup) {
            let dest = createGroup(title: src.title)
            dest.fill(from: src)
            parent.items.append(dest)

            for it in src.items {
                if let station = it as? Station {
                    let new = createStation(title: station.title, url: station.url)
                    new.fill(from: station)
                    dest.items.append(new)
                }

                if let group = it as? StationGroup {
                    addGroup(src: group, parent: dest)
                }
            }
        }

        addGroup(src: group, parent: self)
    }

    /* ****************************************
     *
     * ****************************************/
    func firstStation(where predicate: (Station) -> Bool) -> Station? {
        var queue = items

        while !queue.isEmpty {
            let item = queue.removeFirst()

            if let station = item as? Station {
                if predicate(station) {
                    return station
                }
            }

            if let group = item as? StationGroup {
                queue += group.items
            }
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func firstGroup(where predicate: (StationGroup) -> Bool) -> StationGroup? {
        var queue = items

        while !queue.isEmpty {
            let item = queue.removeFirst()

            if let group = item as? StationGroup {
                if predicate(group) {
                    return group
                }

                queue += group.items
            }
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func favoritesStations() -> [Station] {
        return filterStations { $0.isFavorite }
    }

    /* ****************************************
     *
     * ****************************************/
    private func filterStations(where match: (Station) -> Bool) -> [Station] {
        var res: [Station] = []
        var queue = items

        while !queue.isEmpty {
            let item = queue.removeFirst()

            if let station = item as? Station {
                if match(station) {
                    res.append(station)
                }
            }

            if let group = item as? StationGroup {
                queue.insert(contentsOf: group.items, at: 0)
            }
        }

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    func itemParent(item: StationItem) -> StationGroup? {
        func run(_ group: StationGroup) -> StationGroup? {
            for it in group.items {
                if it.id == item.id {
                    return group
                }

                if let g = it as? StationGroup {
                    if let res = run(g) { return res }
                }
            }
            return nil
        }

        return run(self)
    }

    /* ****************************************
     *
     * ****************************************/
    func dump() {
        func dump(_ item: StationItem, indent: String) {
            if let station = item as? Station {
                print("\(indent)○ [\(station.id)] \(station.title) \(station.url)")
                return
            }

            if let group = item as? StationGroup {
                print("\(indent)▼ [\(group.id)] \(group.title)")

                for item in group.items {
                    dump(item, indent: "  " + indent)
                }
            }
        }

        for item in items {
            dump(item, indent: "")
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func item(byID: UUID) -> StationItem? {
        var queue = items

        while !queue.isEmpty {
            let item = queue.removeFirst()

            if item.id == byID {
                return item
            }

            if let group = item as? StationGroup {
                queue += group.items
            }
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func station(byURL: String) -> Station? {
        return firstStation { $0.url == byURL }
    }
}

// MARK: - extension [StationList]

extension [StationList] {
    func find(byId: UUID) -> (any StationList)? {
        return first { $0.id == byId }
    }
}
