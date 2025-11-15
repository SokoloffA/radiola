//
//  AppState.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 01.12.2023.
//

import CoreData
import Foundation

fileprivate class DefaultStation: Station {
    var id: UUID = UUID()
    var title: String
    var url: String
    var isFavorite: Bool

    init(title: String, url: String, isFavorite: Bool) {
        self.title = title
        self.url = url
        self.isFavorite = isFavorite
    }
}

// MARK: - Settings

fileprivate let defaultOpmlListTitle = NSLocalizedString("My stations", comment: "Station list name")
fileprivate let defaultOpmlListIcon = "music.house"

fileprivate let opmlDirectoryName = "com.github.SokoloffA.Radiola/"
fileprivate let opmlFileName = "bookmarks.opml"

fileprivate func opmlFilePath() -> URL {
    return URL(fileURLWithPath: opmlDirectoryName + "/" + opmlFileName,
               relativeTo: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)
}

fileprivate func opmlFileExists() -> Bool {
    return FileManager.default.fileExists(atPath: opmlFilePath().path)
}

fileprivate func opmlFileDir() -> URL {
    return URL(fileURLWithPath: opmlDirectoryName,
               relativeTo: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)
}

fileprivate let defaultStations: [Station] = [
    DefaultStation(
        title: "Radio Caroline",
        url: "http://sc3.radiocaroline.net:8030",
        isFavorite: true
    ),

    DefaultStation(
        title: "Radio Caroline 319 Gold [ Hits from '60-'70 ]",
        url: "http://www.rcgoldserver.eu:8192",
        isFavorite: true
    ),

    DefaultStation(
        title: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]",
        url: "http://www.rcgoldserver.eu:8253",
        isFavorite: true
    ),
]

// MARK: - AppState

class AppState: ObservableObject {
    static let shared = AppState()
    private var isCloudStationsVisible = false
    private var isOpmlStationsVisible = false

    @Published var localStations: [any StationList] = []

    @Published var internetStations: [InternetStationList] = [
        InternetStationList(title: NSLocalizedString("By tag", comment: "Internet station list"), icon: "globe", provider: RadioBrowserProvider(.byTag)),
        InternetStationList(title: NSLocalizedString("By name", comment: "Internet station list"), icon: "globe", provider: RadioBrowserProvider(.byName)),
        InternetStationList(title: NSLocalizedString("By country", comment: "Internet station list"), icon: "globe", provider: RadioBrowserProvider(.byCountry)),
    ]

    public var history = History()

    /* ****************************************
     *
     * ****************************************/
    init() {
        updateOpmlStations(show: true)
    }

    /* ****************************************
     *
     * ****************************************/
    private func updateOpmlStations(show: Bool) {
        if show == isOpmlStationsVisible {
            return
        }
        isOpmlStationsVisible = show

        if !show {
            localStations.removeAll { $0 is OpmlStations }
            return
        }

        loadDefaultOpmlStations()
        loadUserOpmlStations()
    }

    /* ****************************************
     *
     * ****************************************/
    private func loadDefaultOpmlStations() {
        // Read local stations from bookmark.opml .................................
        let dirName = opmlFileDir()
        let fileName = opmlFilePath()

        if !FileManager.default.fileExists(atPath: dirName.path) {
            do {
                try FileManager.default.createDirectory(at: dirName, withIntermediateDirectories: true)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        debug("Dir of stations: \(dirName.path)")
        debug("Load stations from: \(fileName.path)")

        let opmlList = OpmlStations(icon: defaultOpmlListIcon, file: fileName)
        opmlList.load(defaultStations: defaultStations)
        if opmlList.title.isEmpty {
            opmlList.title = defaultOpmlListTitle
        }
        opmlList.saveToSandbox()
        localStations.append(opmlList)
    }

    /* ****************************************
     *
     * ****************************************/
    private func loadUserOpmlStations() {
        guard let enumerator = FileManager.default.enumerator(at: opmlFileDir(), includingPropertiesForKeys: nil) else { return }

        for case let file as URL in enumerator {
            if file.pathExtension != "opml" || file.lastPathComponent == opmlFileName {
                continue
            }

            let opmlList = OpmlStations(icon: defaultOpmlListIcon, file: file)

            do {
                try opmlList.load()
                if opmlList.title.isEmpty {
                    opmlList.title = file.lastPathComponent.replacingOccurrences(of: ".opml", with: "")
                }
                localStations.append(opmlList)
            } catch {
                error.show()
            }
        }
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
                if let res = list.firstStation(byURL: url) {
                    return res
                }
            }
        }

        if let res = favoritesStations().first {
            return res
        }

        for list in localStations {
            if let res = list.firstStation(where: { _ in true }) {
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
            res = sl.firstStation(byID: byID)
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

    /* ****************************************
     *
     * ****************************************/
    func localStation(byID: UUID?) -> Station? {
        guard let byID = byID else { return nil }

        var res: Station?
        for sl in localStations {
            res = sl.firstStation(byID: byID)
            if res != nil {
                return res
            }
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func localStation(byURL: String) -> Station? {
        var res: Station?
        for sl in localStations {
            res = sl.firstStation(byURL: byURL)
            if res != nil {
                return res
            }
        }

        return nil
    }
}
