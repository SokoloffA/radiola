//
//  LocalStationsProvider.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.09.2023.
//

import Cocoa

/* **********************************************
 *
 * **********************************************/
class StationsStore {
    private let oplDirectoryName = "com.github.SokoloffA.Radiola/"
    private let oplFileName = "bookmarks.opml"

    let localStations = LocalStationList(title: "My staions")
    let internetRequests: [StationList] = [
        RadioBrowserStationsByTag(title: "By tag", settingsPath: "RadioBrowser.com:byTag"),
        RadioBrowserStationsByName(title: "By name", settingsPath: "RadioBrowser.com:byName"),
        RadioBrowserStationsByCountry(title: "By country", settingsPath: "RadioBrowser.com:byCountry"),
    ]

    var stationLists: [StationList] { return [localStations] + internetRequests }

    init() {
        let dirName = URL(
            fileURLWithPath: oplDirectoryName,
            relativeTo: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)

        let fileName = URL(
            fileURLWithPath: oplDirectoryName + "/" + oplFileName,
            relativeTo: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)

        if !FileManager.default.fileExists(atPath: dirName.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: dirName, withIntermediateDirectories: true)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        localStations.load(file: fileName)
    }

    /* ****************************************
     *
     * ****************************************/
    func lastStation() -> Station? {
        let url = settings.lastStationUrl ?? ""

        if !url.isEmpty {
            for list in stationLists {
                let res = list.station(byUrl: url)
                if res != nil {
                    return res
                }
            }
        }

        let res = localStations.favorites().first
        if res != nil {
            return res
        }

        for n in localStations.nodes {
            if let s = n as? Station {
                return s
            }
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func find(byId: Int) -> StationNode? {
        var res: StationNode?
        res = localStations.find(byId: byId)
        return res
    }

    /* ****************************************
     *
     * ****************************************/
    func station(byId: Int) -> Station? {
        return find(byId: byId) as? Station
    }
}

let stationsStore = StationsStore()
