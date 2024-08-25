//
//  StationList.swift
//  Radiola
//
//  Created by Alex Sokolov on 25.08.2024.
//

import Foundation

// MARK: - StationList

protocol StationList: AnyObject {
    var id: UUID {get}
    var title: String { get }
    var icon: String { get }
    var help: String? { get }
    var items: [StationItem] { get set }

    func createStation(title: String, url: String) -> Station
    func createGroup(title: String) -> StationGroup

    func save()
}

extension StationList {
    /* ****************************************
     *
     * ****************************************/
    func first(byURL: String) -> Station? {
        return firstStation { $0.url == byURL }
    }

    /* ****************************************
     *
     * ****************************************/
    func first(byID: UUID) -> Station? {
        return firstStation { $0.id == byID }
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

}

//MARK: - extension [StationList]

extension [StationList] {
    func find(byId: UUID) -> (any StationList)? {
        return first { $0.id == byId }
    }
}
