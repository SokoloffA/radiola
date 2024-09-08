//
//  AppState.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 01.12.2023.
//

import Foundation
import CoreData

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

// MARK: - AppState

fileprivate let oplDirectoryName = "com.github.SokoloffA.Radiola/"
fileprivate let oplFileName = "bookmarks.opml"

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

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var localStations: [any StationList] = []

    @Published var internetStations: [InternetStationList] = [
        InternetStationList(title: "By tag", icon: "globe", provider: RadioBrowserProvider(.byTag)),
        InternetStationList(title: "By name", icon: "globe", provider: RadioBrowserProvider(.byName)),
        InternetStationList(title: "By country", icon: "globe", provider: RadioBrowserProvider(.byCountry)),
    ]

    public var history = History()


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



        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: iCloud.context)
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextWillSave), name: NSNotification.Name.NSManagedObjectContextWillSave, object: iCloud.context)
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextDidSave), name: NSNotification.Name.NSManagedObjectContextDidSave, object: iCloud.context)

        var cloudStations: [CloudStationList] = []
        do {
            try cloudStations.load()
        }
        catch {
            Alarm.show(title: "Unable to load stations from iCloud", message: error.localizedDescription)
        }

        if var cloudStations = loadCloudStationList() {
            print("LOADED ____________________________", cloudStations.count)

//            if cloudStations.isEmpty {
//                debug("Create default iCloud list")
//                let list = CloudStationList(context: iCloud.context)
//
//                list.title = "My stations"
//                list.icon = "music.house"
//                list.id = UUID()
//                list.save()
//
//                cloudStations.append(list)
//            }

            for list in cloudStations {

                print(" *", list.title, list.id )
//                iCloud.context.delete(list)
//                iCloud.save()
            }
        }



        // Read local stations .................................
        debug("Load stations from: \(fileName.path)")
        let opmlList = OpmlStations(title: "My stations", icon: "music.house")
        opmlList.load(file: fileName, defaultStations: defaultStations)
        localStations.append(opmlList)

        let sharedList = SharedStations(title: "Shared", icon: "music.house")
        sharedList.load()
        localStations.append(sharedList)
    }

    @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
             print("--- INSERTS ---")
             print(inserts)
             print("+++++++++++++++")
         }

         if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> , updates.count > 0 {
             print("--- UPDATES ---")
             print(updates)
             for update in updates {
                 print(update.changedValues())
             }
             print("+++++++++++++++")
         }

         if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
             print("--- DELETES ---")
             print(deletes)
             print("+++++++++++++++")
         }

    }

    @objc func managedObjectContextWillSave() {
        print(#function)
    }

    @objc func managedObjectContextDidSave() {
        print(#function)
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
                if let res = list.first(byURL: url) {
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

    /* ****************************************
     *
     * ****************************************/
    func localStation(byID: UUID?) -> Station? {
        guard let byID = byID else { return nil }

        var res: Station?
        for sl in localStations {
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
    func localStation(byURL: String) -> Station? {
        var res: Station?
        for sl in localStations {
            res = sl.first(byURL: byURL)
            if res != nil {
                return res
            }
        }

        return nil
    }
}
