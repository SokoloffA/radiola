//
//  LocalStationsMerger.swift
//  Radiola
//
//  Created by Alex Sokolov on 21.05.2024.
//

import Foundation

// MARK: - LocalStationsMerger

class LocalStationsMerger {
    let currentStations: LocalStationList
    let newStations: LocalStationList
    private(set) var statistics = Statistics()

    struct Statistics {
        var insertedStations = 0
        var updatedStations = 0
        var insertedGroups = 0
    }

    /* ****************************************
     *
     * ****************************************/
    init(currentStations: LocalStationList, newStations: LocalStationList) {
        self.currentStations = currentStations
        self.newStations = newStations
        statGroup(srcGroup: newStations.root, destGroup: currentStations.root)
    }

    /* ****************************************
     *
     * ****************************************/
    private func statGroup(srcGroup: LocalStationGroup, destGroup: LocalStationGroup?) {
        for item in srcGroup.items {
            if let station = item as? LocalStation {
                statStation(src: station, srcParent: srcGroup, destParent: destGroup)
                continue
            }

            if let group = item as? LocalStationGroup {
                statGroup(src: group, srcParent: srcGroup, destParent: destGroup)
                continue
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func statGroup(src: LocalStationGroup, srcParent: LocalStationGroup, destParent: LocalStationGroup?) {
        let group = destParent?.findGroup(src: src)
        if group == nil {
            statistics.insertedGroups += 1
        }

        statGroup(srcGroup: src, destGroup: group)
    }

    /* ****************************************
     *
     * ****************************************/
    private func statStation(src: LocalStation, srcParent: LocalStationGroup, destParent: LocalStationGroup?) {
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
        mergeGroup(srcGroup: newStations.root, destGroup: currentStations.root)
    }

    /* ****************************************
     *
     * ****************************************/
    private func mergeGroup(srcGroup: LocalStationGroup, destGroup: LocalStationGroup) {
        for item in srcGroup.items {
            if let station = item as? LocalStation {
                processStation(src: station, srcParent: srcGroup, destParent: destGroup)
                continue
            }

            if let group = item as? LocalStationGroup {
                processGroup(src: group, srcParent: srcGroup, destParent: destGroup)
                continue
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func processGroup(src: LocalStationGroup, srcParent: LocalStationGroup, destParent: LocalStationGroup) {
        var group = destParent.findGroup(src: src)

        if group == nil {
            let index = insertIndex(src: src, srcParent: srcParent, destParent: destParent)
            group = LocalStationGroup(title: src.title)
            destParent.items.insert(group!, at: index)
        }

        mergeGroup(srcGroup: src, destGroup: group!)
    }

    /* ****************************************
     *
     * ****************************************/
    private func processStation(src: LocalStation, srcParent: LocalStationGroup, destParent: LocalStationGroup) {
        if let station = destParent.findStation(src: src) {
            station.title = src.title
            station.isFavorite = src.isFavorite
            return
        }

        let index = insertIndex(src: src, srcParent: srcParent, destParent: destParent)
        let station = LocalStation(title: src.title, url: src.url, isFavorite: src.isFavorite)
        destParent.items.insert(station, at: index)
    }

    /* ****************************************
     *
     * ****************************************/
    private func insertIndex(src: LocalStationItem, srcParent: LocalStationGroup, destParent: LocalStationGroup) -> Int {
        guard let n = srcParent.items.firstIndex(where: { $0.id == src.id }) else { return 0 }

        if n == 0 {
            return 0
        }

        let srcPrev = srcParent.items[n - 1]

        if let s = srcPrev as? LocalStation {
            if let n = destParent.items.firstIndex(where: { ($0 as? LocalStation)?.url == s.url }) {
                return n + 1
            }
        }

        if let g = srcPrev as? LocalStationGroup {
            if let n = destParent.items.firstIndex(where: { ($0 as? LocalStationGroup)?.title == g.title }) {
                return n + 1
            }
        }

        return 0
    }
}

// MARK: - LocalStationGroup

fileprivate extension LocalStationGroup {
    func findStation(src: LocalStation) -> LocalStation? {
        let res = items.first { ($0 as? LocalStation)?.url == src.url && ($0 as? LocalStation)?.title == src.title } as? LocalStation
        if res != nil { return res }

        return items.first { ($0 as? LocalStation)?.url == src.url } as? LocalStation
    }

    func findGroup(src: LocalStationGroup) -> LocalStationGroup? {
        return items.first { ($0 as? LocalStationGroup)?.title == src.title } as? LocalStationGroup
    }
}
