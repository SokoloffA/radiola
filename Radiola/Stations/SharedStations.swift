//
//  SharedStations.swift
//  Radiola
//
//  Created by Alex Sokolov on 25.08.2024.
//

import CoreData

class SharedStationItem: NSManagedObject, StationItem {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged fileprivate var parentId: UUID?

//    public override func awakeFromInsert() {
//            super.awakeFromInsert()
//            id = UUID()
//    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SharedStationItem> {
        return NSFetchRequest<SharedStationItem>(entityName: "SharedStationItem")
    }
}

class SharedStation: SharedStationItem, Station {
    @NSManaged var url: String
    @NSManaged var isFavorite: Bool

//    public override func awakeFromInsert() {
//            super.awakeFromInsert()
//      isFavorite = false
//    }
}

class SharedStationGroup: SharedStationItem, StationGroup {
    var items: [any StationItem] = []
//    @NSManaged public var items: NSSet?
}

class SharedStations: StationList {
    var id: UUID = UUID()
    var title: String
    var icon: String
    var help: String?
    var items: [any StationItem] = []

    private var persistentContainer: NSPersistentContainer
    private     var context: NSManagedObjectContext

    init(    title: String, icon: String, help: String? = nil) {
        self.title = title
        self.icon = icon
        self.help = help

        self.persistentContainer = NSPersistentContainer(name: "Radiola")
        persistentContainer.loadPersistentStores { _, error in
                  if let error = error as Error? {
                      Alarm.show(title: "Can't load shared stations", message: error.localizedDescription)
                      return
                  }
              }

        self.context = persistentContainer.viewContext
    }

    func load() {
        let fetchRequest = SharedStationItem.fetchRequest()
//        let fetchRequest = NSFetchRequest<SharedStationItem>(entityName: "SharedStationItem")
        do {
            let objects = try context.fetch(fetchRequest)
            for o in objects {
                print("@@@", o.title, o is SharedStation)
            }
        }
        catch {
            Alarm.show(title: "Can't load shared stations", message: error.localizedDescription)
            return
        }
    }

    func save() {
        if context.hasChanges {
                  do {
                      try context.save()
                  } catch {
                    context.rollback()
                      Alarm.show(title: "Can't save the stations", message: error.localizedDescription)
                  }
              }
    }

    func createStation(title: String, url: String) -> any Station {
        let res = SharedStation(context: context)
        res.id =  UUID()
        res.title = title
        res.url = url
        res.isFavorite = false
        return res;
    }

    func createGroup(title: String) -> any StationGroup {
        let res = SharedStationGroup(context: context)
        res.id =  UUID()
        res.title = title
        return res;
    }

}
