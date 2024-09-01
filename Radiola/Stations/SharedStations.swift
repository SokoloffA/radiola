//
//  SharedStations.swift
//  Radiola
//
//  Created by Alex Sokolov on 25.08.2024.
//

import CoreData

// MARK: - SharedStationRecord

class SharedStationRecord: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var url: String
    @NSManaged var isFavorite: Bool
    @NSManaged fileprivate var parentId: UUID?
    @NSManaged var order: Int

    @nonobjc class func fetchRequest() -> NSFetchRequest<SharedStationRecord> {
        return NSFetchRequest<SharedStationRecord>(entityName: "SharedStationRecord")
    }

    fileprivate func setParent(_ value: UUID?) {
        if parentId != value { parentId = value }
    }

    fileprivate func setOrder(_ value: Int) {
        if order != value { order = value }
    }
}

// MARK: - SharedStation

class SharedStation: Station {
    var id: UUID { data.id }
    var title: String { get { data.title } set { data.title = newValue }}
    var url: String { get { data.url } set { data.url = newValue }}
    var isFavorite: Bool { get { data.isFavorite } set { data.isFavorite = newValue }}

    fileprivate let data: SharedStationRecord

    fileprivate init(data: SharedStationRecord) {
        self.data = data
    }
}

// MARK: - SharedStationGroup

class SharedStationGroup: StationGroup {
    var id: UUID { data.id }
    var title: String { get { data.title } set { data.title = newValue }}

    fileprivate let data: SharedStationRecord
    var items: [any StationItem] = []

    fileprivate init(data: SharedStationRecord) {
        self.data = data
    }
}

// MARK: - SharedStations

class SharedStations: StationList {
    let id: UUID = UUID()
    var title: String
    var icon: String
    var help: String?
    var items: [any StationItem] = []

    private var persistentContainer: NSPersistentContainer
    private var context: NSManagedObjectContext

    init(title: String, icon: String, help: String? = nil) {
        self.title = title
        self.icon = icon
        self.help = help

        persistentContainer = NSPersistentContainer(name: "Radiola")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error as Error? {
                Alarm.show(title: "Unable to load shared stations", message: error.localizedDescription)
                return
            }
        }

        context = persistentContainer.viewContext
    }

    /* ****************************************
     *
     * ****************************************/
    func createStation(title: String, url: String) -> any Station {
        let data = SharedStationRecord(context: context)
        data.id = UUID()
        data.title = title
        data.url = url
        data.isFavorite = false
        return SharedStation(data: data)
    }

    /* ****************************************
     *
     * ****************************************/
    func createGroup(title: String) -> any StationGroup {
        let data = SharedStationRecord(context: context)
        data.id = UUID()
        data.title = title
        data.url = ""
        return SharedStationGroup(data: data)
    }

    /* ****************************************
     *
     * ****************************************/
    func load() {
        var recs: [SharedStationRecord] = []

        let fetchRequest = SharedStationRecord.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        do {
            recs = try context.fetch(fetchRequest)
        } catch {
            Alarm.show(title: "Unable to load shared stations", message: error.localizedDescription)
            return
        }

        func loadGroup(topGroup: StationGroup, parentId: UUID?) {
            for rec in recs {
                if rec.parentId != parentId {
                    continue
                }

                if rec.url.isEmpty {
                    let group = SharedStationGroup(data: rec)
                    topGroup.items.append(group)
                    loadGroup(topGroup: group, parentId: group.id)
                } else {
                    let station = SharedStation(data: rec)
                    topGroup.items.append(station)
                }
            }
        }

//        for rec in recs {
//            print(" * ", rec.order, " ::  ", rec.title, "<", rec.url, "> [", rec.id, "] PARENT", rec.parentId)
//        }

        loadGroup(topGroup: self, parentId: nil)
    }

    /* ****************************************
     *
     * ****************************************/
    func save() {
        func fix(parent: StationGroup, parentId: UUID?) {
            var i = 0
            for it in parent.items {
                i += 1

                if let station = it as? SharedStation {
                    station.data.setParent(parentId)
                    station.data.setOrder(i)
                } else if let group = it as? SharedStationGroup {
                    group.data.setParent(parentId)
                    group.data.setOrder(i)

                    fix(parent: group, parentId: group.id)
                }
            }
        }

        fix(parent: self, parentId: nil)

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                context.rollback()
                Alarm.show(title: "Unable to save shared stations", message: error.localizedDescription)
            }
        }
    }
}
