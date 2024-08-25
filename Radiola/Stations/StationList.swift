//
//  StationList.swift
//  Radiola
//
//  Created by Alex Sokolov on 25.08.2024.
//

import Foundation

// MARK: - StationList

protocol StationList: StationGroup {
    var id: UUID {get}
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
}

//MARK: - extension [StationList]

extension [StationList] {
    func find(byId: UUID) -> (any StationList)? {
        return first { $0.id == byId }
    }
}
