//
//  StationsProvider.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 05.09.2023.
//

import Cocoa

struct SearchOrder: RawRepresentable {
    var rawValue: String
}

protocol SearchProvider {
    var title: String { get }
    var stations: StationList { get }
    var searchText: String { get set }

    var isExactMatch: Bool { get set }

    var allOrderTypes: [SearchOrder] { get }
    var order: SearchOrder { get set }

    func fetch() async throws
}
