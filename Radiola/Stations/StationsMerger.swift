//
//  StationsMerger.swift
//  Radiola
//
//  Created by Alex Sokolov on 21.05.2024.
//

import Foundation

// MARK: - StationsMerger

class StationsMerger {
    let currentStations: StationList
    let newStations: StationList
    private(set) var statistics = Statistics()

    struct Statistics {
        var insertedStations = 0
        var updatedStations = 0
        var insertedGroups = 0

        var isEmpty: Bool {
            return
                insertedStations == 0 &&
                updatedStations == 0 &&
                insertedGroups == 0
        }
    }

    /* ****************************************
     *
     * ****************************************/
    init(currentStations: StationList, newStations: StationList) {
        self.currentStations = currentStations
        self.newStations = newStations
        statGroup(srcGroup: newStations, destGroup: currentStations)
    }

    /* ****************************************
     *
     * ****************************************/
    private func statGroup(srcGroup: StationGroup, destGroup: StationGroup?) {
        for item in srcGroup.items {
            if let station = item as? Station {
                statStation(src: station, srcParent: srcGroup, destParent: destGroup)
                continue
            }

            if let group = item as? StationGroup {
                statGroup(src: group, srcParent: srcGroup, destParent: destGroup)
                continue
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func statGroup(src: StationGroup, srcParent: StationGroup, destParent: StationGroup?) {
        let group = destParent?.findGroup(src: src)
        if group == nil {
            statistics.insertedGroups += 1
        }

        statGroup(srcGroup: src, destGroup: group)
    }

    /* ****************************************
     *
     * ****************************************/
    private func statStation(src: Station, srcParent: StationGroup, destParent: StationGroup?) {
        if let station = destParent?.findStation(src: src) {
            if station.title != src.title || station.isFavorite != src.isFavorite {
                statistics.updatedStations += 1
            }
            return
        }

        statistics.insertedStations += 1
    }

    /* ****************************************
     *
     * ****************************************/
    func run() {
        mergeGroup(srcGroup: newStations, destGroup: currentStations)
    }

    /* ****************************************
     *
     * ****************************************/
    private func mergeGroup(srcGroup: StationGroup, destGroup: StationGroup) {
        for item in srcGroup.items {
            if let station = item as? Station {
                processStation(src: station, srcParent: srcGroup, destParent: destGroup)
                continue
            }

            if let group = item as? StationGroup {
                processGroup(src: group, srcParent: srcGroup, destParent: destGroup)
                continue
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func processGroup(src: StationGroup, srcParent: StationGroup, destParent: StationGroup) {
        var group = destParent.findGroup(src: src)

        if group == nil {
            let index = insertIndex(src: src, srcParent: srcParent, destParent: destParent)
            group = newStations.createGroup(title: src.title)
            destParent.items.insert(group!, at: index)
        }

        mergeGroup(srcGroup: src, destGroup: group!)
    }

    /* ****************************************
     *
     * ****************************************/
    private func processStation(src: Station, srcParent: StationGroup, destParent: StationGroup) {
        if let station = destParent.findStation(src: src) {
            station.title = src.title
            station.isFavorite = src.isFavorite
            return
        }

        let index = insertIndex(src: src, srcParent: srcParent, destParent: destParent)
        let station = newStations.createStation(title: src.title, url: src.url)
        station.isFavorite = src.isFavorite
        destParent.items.insert(station, at: index)
    }

    /* ****************************************
     *
     * ****************************************/
    private func insertIndex(src: StationItem, srcParent: StationGroup, destParent: StationGroup) -> Int {
        guard let n = srcParent.items.firstIndex(where: { $0.id == src.id }) else { return 0 }

        if n == 0 {
            return 0
        }

        let srcPrev = srcParent.items[n - 1]

        if let s = srcPrev as? Station {
            if let n = destParent.items.firstIndex(where: { ($0 as? Station)?.url == s.url }) {
                return n + 1
            }
        }

        if let g = srcPrev as? StationGroup {
            if let n = destParent.items.firstIndex(where: { ($0 as? StationGroup)?.title == g.title }) {
                return n + 1
            }
        }

        return 0
    }
}

// MARK: - StationGroup

fileprivate extension StationGroup {
    func findStation(src: Station) -> Station? {
        let res = items.first { ($0 as? Station)?.url == src.url && ($0 as? Station)?.title == src.title } as? Station
        if res != nil { return res }

        return items.first { ($0 as? Station)?.url == src.url } as? Station
    }

    func findGroup(src: StationGroup) -> StationGroup? {
        return items.first { ($0 as? StationGroup)?.title == src.title } as? StationGroup
    }
}
