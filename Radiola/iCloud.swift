//
//  iCloud.swift
//  Radiola
//
//  Created by Alex Sokolov on 07.09.2024.
//

import CoreData

// MARK: - ICloud

class ICloud {

    private var persistentContainer: NSPersistentCloudKitContainer
    let context: NSManagedObjectContext

    /* ****************************************
     *
     * ****************************************/
    fileprivate init() {
        persistentContainer = NSPersistentCloudKitContainer(name: "Radiola")
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true

        persistentContainer.loadPersistentStores { _, error in
            if let error = error as Error? {
                warning(error)
                Alarm.show(title: "Unable to load iCloud data", message: error.localizedDescription)
                return
            }
        }

        context = persistentContainer.viewContext
    }

    /* ****************************************
     *
     * ****************************************/
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                context.rollback()
                warning(error)
                Alarm.show(title: "Unable to save iCloud data", message: error.localizedDescription)
            }
        }
    }
}

var iCloud = ICloud()
