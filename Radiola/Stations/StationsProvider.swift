//
//  StationsProvider.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 05.09.2023.
//

import Cocoa

protocol StationsProvider {
    var title: String { get }
    var stations: StationList { get }
    var searchText: String { get set }

    func fetch() async throws
}
