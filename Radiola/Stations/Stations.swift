//
//  Stations.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 01.12.2023.
//

import Foundation

// MARK: - Station

protocol Station {
    var id: UUID { get }
    var title: String { get set }
    var url: String { get set }
}

// MARK: - StationList

protocol StationList: Identifiable {
    var title: String { get }
    var icon: String { get }
    var help: String? { get }

    func firstStation(where: (Station) -> Bool) -> Station?
}

extension StationList {
    /* ****************************************
     *
     * ****************************************/
    func first(byURL: String) -> Station? {
        return firstStation { $0.url == byURL }
    }

    /* ****************************************
     *
     * ****************************************/
    func first(byID: UUID) -> Station? {
        return firstStation { $0.id == byID }
    }
}
