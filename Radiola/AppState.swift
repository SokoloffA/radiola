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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateStationLists),
                                               name: Notification.Name.SettingsChanged,
                                               object: nil)

        var needImport = false

        // If this is the first run and the OPML file exists, then we show the wizard
        if !settings.isStationsListModeSet && opmlFileExists() {
            StationListWizard.show()
            needImport = settings.stationsListMode == .cloud
        }

        updateStationLists()

        if needImport {
            importOpmlToCloud()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func updateStationLists() {
        if isCloudStationsVisible != settings.isShowCloudStations() || isOpmlStationsVisible != settings.isShowOpmlStations() {
            updateCloudStations(show: settings.isShowCloudStations())
            updateOpmlStations(show: settings.isShowOpmlStations())

            if StationsWindow.isActie() {
                StationsWindow.close()
                StationsWindow.show()
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func updateCloudStations(show: Bool) {
        if show == isCloudStationsVisible {
            return
        }
        isCloudStationsVisible = show

        if !show {
            localStations.removeAll { $0 is CloudStationList }
            return
        }

        // Read iCloud stations ..............................
        do {
            var cloudLists = [CloudStationList]()
            try cloudLists.load()
            for list in cloudLists {
                try list.load()
                localStations.append(list)
            }
        } catch {
            Alarm.show(title: "Sorry, we couldn't load iCloud stations.", message: error.localizedDescription)
        }
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

        // Read local stations .................................
        let dirName = opmlFileDir()
        let fileName = opmlFilePath()

        if !FileManager.default.fileExists(atPath: dirName.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: dirName, withIntermediateDirectories: true)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        debug("Load stations from: \(fileName.path)")
        let opmlList = OpmlStations(title: "Local stations", icon: "music.house", file: fileName)
        opmlList.load(defaultStations: defaultStations)
        localStations.append(opmlList)
    }

    /* ****************************************
     *
     * ****************************************/
    private func importOpmlToCloud() {
        guard let cloudList = localStations.first(where: { $0 is CloudStationList }) else { return }

        let opmlList = OpmlStations(title: "", icon: "", file: opmlFilePath())
        do {
            try opmlList.load()
        } catch {
            error.show()
            return
        }

        let merger = StationsMerger(currentStations: cloudList, newStations: opmlList)
        merger.run()
        cloudList.trySave()
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
