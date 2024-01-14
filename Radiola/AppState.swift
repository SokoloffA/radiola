//
//  AppState.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 01.12.2023.
//

import Foundation

// MARK: - AppState

fileprivate let oplDirectoryName = "com.github.SokoloffA.Radiola/"
fileprivate let oplFileName = "bookmarks.opml"

fileprivate let defaultStations: [LocalStation] = [
    LocalStation(
        title: "Radio Caroline",
        url: "http://sc3.radiocaroline.net:8030",
        isFavorite: true
    ),

    LocalStation(
        title: "Radio Caroline 319 Gold [ Hits from '60-'70 ]",
        url: "http://www.rcgoldserver.eu:8192",
        isFavorite: true
    ),

    LocalStation(
        title: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]",
        url: "http://www.rcgoldserver.eu:8253",
        isFavorite: true
    ),
]

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var localStations: [LocalStationList] = [
        LocalStationList(title: "My stations", icon: "music.house", help: nil),
        LocalStationList(title: "My stations2", icon: "music.house", help: nil),
    ]

    @Published var internetStations: [InternetStationList] = [
        InternetStationList(title: "By tag", icon: "globe", help: nil, provider: RadioBrowserProvider(.byTag)),
        InternetStationList(title: "By name", icon: "globe", help: nil, provider: RadioBrowserProvider(.byName)),
        InternetStationList(title: "By country", icon: "globe", help: nil, provider: RadioBrowserProvider(.byCountry)),
    ]

    /* ****************************************
     *
     * ****************************************/
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

        localStations[0].load(file: fileName, defaultStations: defaultStations)
        localStations[1].load(file: fileName, defaultStations: defaultStations)
//        localStations[1].items.re
    }

    /* ****************************************
     *
     * ****************************************/
    func favoritesStations() -> [Station] {
        var res = [Station]()
        for list in localStations {
            res += list.favoritesStations()
        }
        return res
    }

    /* ****************************************
     *
     * ****************************************/
    func lastStation() -> Station? {
        let url = settings.lastStationUrl ?? ""

        if !url.isEmpty {
            for list in localStations {
                if let res = list.first(byUrl: url) {
                    return res
                }
            }
        }

        if let res = favoritesStations().first {
            return res
        }

        for list in localStations {
            if let res = list.first(where: { _ in true }) {
                return res
            }
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func station(byID: UUID?) -> Station? {
        guard let byID = byID else { return nil }

        var res: Station?
        for sl in localStations {
            res = sl.first(byID: byID)
            if res != nil {
                return res
            }
        }

        for sl in internetStations {
            res = sl.first(byID: byID)
            if res != nil {
                return res
            }
        }

        return nil
    }
}
