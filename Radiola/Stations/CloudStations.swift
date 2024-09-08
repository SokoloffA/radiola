//
//  CloudStationList.swift
//  Radiola
//
//  Created by Alex Sokolov on 07.09.2024.
//

import CoreData
import Foundation

//MARK: - CloudStationList

class CloudStationList: NSManagedObject, StationList {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var icon: String
    @NSManaged var order: Int

    var items: [any StationItem] = []
    private var savedRecords: [UUID: CloudStationRecord] = [:]

    /* ****************************************
     *
     * ****************************************/
    @nonobjc class func fetchRequest() -> NSFetchRequest<CloudStationList> {
        return NSFetchRequest<CloudStationList>(entityName: "CloudStationList")
    }

    /* ****************************************
     *
     * ****************************************/
    func createStation(title: String, url: String) -> any Station {
        return CloudStation(title: title, url: url)
    }

    /* ****************************************
     *
     * ****************************************/
    func createGroup(title: String) -> any StationGroup {
        return CloudStationGroup(title: title)
    }

    /* ****************************************
     *
     * ****************************************/
    private func fetchRecords(parentId: UUID) throws -> [CloudStationRecord] {
        let fetchRequest = CloudStationRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "parentId == %@", parentId as CVarArg)
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        return try iCloud.context.fetch(fetchRequest)
    }

    /* ****************************************
     *
     * ****************************************/
    func load() throws {
        func loadGroup(topGroup: StationGroup) throws {
            let recs = try fetchRecords(parentId: topGroup.id)

            for rec in recs {
                savedRecords[rec.id] = rec

                if rec.url.isEmpty {
                    let group = CloudStationGroup(data: rec)
                    topGroup.items.append(group)
                    try loadGroup(topGroup: group)
                } else {
                    let station = CloudStation(data: rec)
                    topGroup.items.append(station)
                }
            }
        }

        items = []
        savedRecords = [:]
        try loadGroup(topGroup: self)
    }


    /* ****************************************
     *
     * ****************************************/
    func save() throws  {
        var forDelete = savedRecords
        savedRecords.removeAll()

        func fix(parent: StationGroup) {
            var i = 0
            for it in parent.items {
                i += 1

                if let station = it as? CloudStation {
                    station.data.setParent(parent.id)
                    station.data.setOrder(i)
                    savedRecords[station.id] = station.data
                    forDelete.removeValue(forKey: station.id)

                } else if let group = it as? CloudStationGroup {
                    group.data.setParent(parent.id)
                    group.data.setOrder(i)

                    savedRecords[group.id] = group.data
                    forDelete.removeValue(forKey: group.id)

                    fix(parent: group)
                }
            }
        }

        fix(parent: self)

        for rec in forDelete.values {
            iCloud.context.delete(rec)
        }

        if iCloud.context.hasChanges {
            do {
                try iCloud.context.save()
            } catch {
                iCloud.context.rollback()
                throw error
            }
        }
    }
}

class CloudStationRecord: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var url: String
    @NSManaged var isFavorite: Bool
    @NSManaged fileprivate var parentId: UUID?
    @NSManaged var order: Int

    @nonobjc class func fetchRequest() -> NSFetchRequest<CloudStationRecord> {
        return NSFetchRequest<CloudStationRecord>(entityName: "CloudStationRecord")
    }

    fileprivate func setParent(_ value: UUID?) {
        if parentId != value { parentId = value }
    }

    fileprivate func setOrder(_ value: Int) {
        if order != value { order = value }
    }
}


// MARK: - CloudStation

class CloudStation: Station {
    var id: UUID { data.id }
    var title: String { get { data.title } set { data.title = newValue }}
    var url: String { get { data.url } set { data.url = newValue }}
    var isFavorite: Bool { get { data.isFavorite } set { data.isFavorite = newValue }}

    fileprivate let data: CloudStationRecord

    fileprivate init(title: String, url: String, isFavorite: Bool = false) {
        self.data = CloudStationRecord(context: iCloud.context)
        data.id = UUID()
        data.title = title
        data.url = url
        data.isFavorite = isFavorite
    }

    fileprivate init(data: CloudStationRecord) {
        self.data = data
    }
}

// MARK: - CloudStationGroup

class CloudStationGroup: StationGroup {
    var id: UUID { data.id }
    var title: String { get { data.title } set { data.title = newValue }}

    fileprivate let data: CloudStationRecord
    var items: [any StationItem] = []

    fileprivate init(title: String) {
        self.data = CloudStationRecord(context: iCloud.context)
        data.id = UUID()
        data.title = title
        data.url = ""
    }

    fileprivate init(data: CloudStationRecord) {
        self.data = data
    }
}

//MARK: - [CloudStationList]

extension [CloudStationList] {

    /* ****************************************
     *
     * ****************************************/
    mutating func load() throws {
        let fetchRequest = CloudStationList.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        do {
            self = try iCloud.context.fetch(fetchRequest)
        } catch {
            warning(error)
            throw(error)
        }
    }
}
