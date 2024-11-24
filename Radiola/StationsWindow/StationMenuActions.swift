//
//  StationActions.swift
//  Radiola
//
//  Created by Alex Sokolov on 08.09.2024.
//

import Cocoa

//class MenuAction: NSObject {
//
//    private let action: () -> Void
//
//    init(action: @escaping () -> Void) {
//        self.action = action
//    }
//
//    @objc func executeAction() {
//        action()
//    }
//}

class StationAction {
    let title: String
    weak var station: (any Station)?

    init(title: String, station: any Station) {
        self.station = station
        self.title = title
    }

    @objc func execute() {
    }
}

class CopyStationToList: StationAction {
    weak var list: (any StationList)?

    init(station: Station, list: StationList) {
        super.init(title: "Cpy station to \(list.title)", station: station)
    }

    @objc override func execute() {
        print("COPY \(station?.title) => \(list?.title)")
    }
}

class MenuItem_CopyStationToList: NSMenuItem {
    let station: (any Station)?
    let list: (any StationList)?

    init(station: Station, list: StationList) {
        self.station = station
        self.list = list
        super.init(title: "Cpy station to \(list.title)", action: #selector(execute), keyEquivalent: "")
        self.target = self
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func execute() {
        print("COPY \(station?.title) => \(list?.title)")
    }

}
