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

    /* ****************************************
     *
     * ****************************************/
    func deleteAll_UseOnlyForDebug() {
        persistentContainer.managedObjectModel.entities.forEach { entity in
            guard let entityName = entity.name else { return }

            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try context.execute(deleteRequest)
                try context.save()
                print("Удалены все данные для сущности \(entityName)")
            } catch {
                print("Ошибка удаления данных для сущности \(entityName): \(error)")
            }
        }
    }
}

var iCloud = ICloud()
