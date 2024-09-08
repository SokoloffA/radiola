//
//  CloudStationList.swift
//  Radiola
//
//  Created by Alex Sokolov on 07.09.2024.
//

import CoreData
import Foundation

//MARK: - CloudStationList

class CloudStationList: NSManagedObject {
    var items: [any StationItem] = []

    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var icon: String
    @NSManaged var order: Int



//    /* ****************************************
//     *
//     * ****************************************/
//    override public func awakeFromInsert() {
//        super.awakeFromInsert()
//        id = UUID()
//    }

    /* ****************************************
     *
     * ****************************************/
    @nonobjc class func fetchRequest() -> NSFetchRequest<CloudStationList> {
        return NSFetchRequest<CloudStationList>(entityName: "CloudStationList")
    }


    /* ****************************************
     *
     * ****************************************/
    func save() {
        iCloud.save()
    }




}

func loadCloudStationList() -> [CloudStationList]? {
    let fetchRequest = CloudStationList.fetchRequest()
    let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
    fetchRequest.sortDescriptors = [sortDescriptor]

    do {
        var res: [CloudStationList] = []
        res = try iCloud.context.fetch(fetchRequest)
        return res
    } catch {
        warning(error)
        Alarm.show(title: "Unable to load shared stations", message: error.localizedDescription)
        return nil
    }
}

//MARK: -[CloudStationList]
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

//    mutating func addDefaultList(stations: [Station]) {
//        let list = CloudStationList(context: iCloud.context)
//
//        list.title = "My stations"
//        list.icon = "music.house"
//        list.id = UUID()
//        for station in stations {
//            list.addSt
//        }
//        list.
//        list.save()
//    }

}
