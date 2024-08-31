//
//  History.swift
//  Radiola
//
//  Created by Alex Sokolov on 30.04.2024.
//

import CoreData
import Foundation

// MARK: - HistoryRecord

class HistoryRecord: NSManagedObject {
    @NSManaged fileprivate(set) var song: String
    @NSManaged fileprivate(set) var stationTitle: String
    @NSManaged fileprivate(set) var stationURL: String
    @NSManaged fileprivate(set) var date: Date
    @NSManaged fileprivate var favorite: Bool

    var isFavorite: Bool {
        get {
            return favorite
        }
        set {
            favorite = newValue
            save()
        }
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HistoryRecord> {
        return NSFetchRequest<HistoryRecord>(entityName: "HistoryRecord")
    }

    func save() {
        guard let context = managedObjectContext else { return }
        saveContext(context: context)
    }
}

// MARK: - History

class History {
    private var maxDaysCount = 100
    public var records: [HistoryRecord] = []
    var last: HistoryRecord? { return records.last }

    private var persistentContainer: NSPersistentContainer
    private var context: NSManagedObjectContext

    /* ****************************************
     *
     * ****************************************/
    init() {
        persistentContainer = NSPersistentContainer(name: "HistoryData")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error as Error? {
                Alarm.show(title: "Unable to load history records", message: error.localizedDescription)
                return
            }
        }

        context = persistentContainer.viewContext
        removeOldRecords()

        let fetchRequest = HistoryRecord.fetchRequest()
        do {
            records = try context.fetch(fetchRequest)
        } catch {
            Alarm.show(title: "Unable to load history records", message: error.localizedDescription)
            return
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func removeOldRecords() {
        let calendar = Calendar.current
        guard let date100DaysAgo = calendar.date(byAdding: .day, value: -maxDaysCount, to: Date()) else { return }
        let fetchRequest: NSFetchRequest<HistoryRecord> = HistoryRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date < %@", date100DaysAgo as NSDate)

        do {
            for rec in try context.fetch(fetchRequest) {
                debug("remove old history record", rec.date)
                context.delete(rec)
            }

            try context.save()

        } catch let error as NSError {
            Alarm.show(title: "Unable to remove old history records", message: error.localizedDescription)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func add(station: Station, songTitle: String) {
        let last = records.last
        if last?.song == songTitle && last?.stationURL == station.url {
            return
        }

        let rec = HistoryRecord(context: context)
        rec.date = Date()
        rec.song = songTitle
        rec.stationURL = station.url
        rec.stationTitle = station.title
        rec.favorite = false

        records.append(rec)
        save()
    }

    /* ****************************************
     *
     * ****************************************/
    func save() {
        saveContext(context: context)
    }

    /* ****************************************
     *
     * ****************************************/
    func favorites() -> [HistoryRecord] {
        return records.filter { $0.favorite }
    }
}

/* ****************************************
 *
 * ****************************************/
fileprivate func saveContext(context: NSManagedObjectContext) {
    if context.hasChanges {
        do {
            try context.save()
        } catch {
            context.rollback()
            Alarm.show(title: "Can't save the history", message: error.localizedDescription)
        }
    }
}
