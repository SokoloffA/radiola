//
//  StationProvider.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.09.2023.
//

import Cocoa

private let defaultStations: [Station] = [
    Station(
        title: "Radio Caroline",
        url: "http://sc3.radiocaroline.net:8030",
        isFavorite: true
    ),

    Station(
        title: "Radio Caroline 319 Gold [ Hits from '60-'70 ]",
        url: "http://www.rcgoldserver.eu:8192",
        isFavorite: true
    ),

    Station(
        title: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]",
        url: "http://www.rcgoldserver.eu:8253",
        isFavorite: true
    ),
]

/* **********************************************
 * Station Node
 * **********************************************/
class StationNode {
    private static var lastId = 0
    let id: Int = { lastId += 1; return lastId }()
    var title: String = ""
    weak var parent: StationGroup?

    /* **************************************
     *
     * **************************************/
    func stationList() -> StationList? {
        var p = parent
        while p != nil {
            if let res = p as? StationList {
                return res
            }
            p = p?.parent
        }

        return nil
    }
}

/* ******************************************
 * Station
 * ******************************************/
class Station: StationNode {
    var url: String
    var isFavorite = false
    var bitrate: Bitrate?
    var votes: Int?

    /* ****************************************
     *
     * ****************************************/
    init(title: String, url: String, isFavorite: Bool = false) {
        self.url = url
        self.isFavorite = isFavorite
        super.init()
        self.title = title
    }

    /* ****************************************
     *
     * ****************************************/
    var isEmpty: Bool {
        return url.isEmpty
    }
}

/* **********************************************
 * Station Group
 * **********************************************/
class StationGroup: StationNode {
    var nodes: [StationNode] = [] {
        didSet {
            for n in nodes {
                n.parent = self
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    init(title: String = "") {
        super.init()
        self.title = title
    }

    /* ****************************************
     *
     * ****************************************/
    func find(where f: (StationNode) -> Bool) -> StationNode? {
        var queue: [StationNode] = [self]

        while !queue.isEmpty {
            let n = queue.removeFirst()

            if f(n) {
                return n
            }

            if let g = n as? StationGroup {
                queue += g.nodes
            }
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func find(byId: Int) -> StationNode? {
        return find { $0.id == byId }
    }

    /* ****************************************
     *
     * ****************************************/
    func index(_ node: StationNode) -> Int? {
        return nodes.firstIndex { $0.id == node.id }
    }

    /* ****************************************
     *
     * ****************************************/
    func contains(_ node: StationNode) -> Bool {
        return nodes.contains(where: { $0 === node })
    }

    /* ****************************************
     *
     * ****************************************/
    func append(_ node: StationNode) {
        nodes.append(node)
    }

    /* ****************************************
     *
     * ****************************************/
    func insert(_ node: StationNode, at: Int) {
        nodes.insert(node, at: at)
    }

    /* ****************************************
     *
     * ****************************************/
    func insert(_ node: StationNode, after: StationNode) {
        let index = nodes.firstIndex { $0.id == after.id }

        if let index = index {
            if index < nodes.count - 1 {
                insert(node, at: index + 1)
            } else {
                append(node)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func remove(_ node: StationNode) {
        let index = nodes.firstIndex { $0.id == node.id }

        if let index = index {
            nodes.remove(at: index)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func removeAll() {
        nodes.removeAll()
    }
}

/* **********************************************
 * Station List
 * **********************************************/
class StationList: StationGroup {
    var isEditable: Bool { return false }

    /* ****************************************
     *
     * ****************************************/
    func station(byUrl: String) -> Station? {
        return find { ($0 as? Station)?.url == byUrl } as? Station
    }

    /* ****************************************
     *
     * ****************************************/
    private func filterStations(where f: (Station) -> Bool) -> [Station] {
        var res: [Station] = []
        var queue: [StationNode] = nodes

        while !queue.isEmpty {
            let node = queue[0]
            queue.removeFirst()

            if let station = node as? Station {
                if f(station) { res.append(station) }
            } else if let group = node as? StationGroup {
                queue.insert(contentsOf: group.nodes, at: 0)
            }
        }

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    func favorites() -> [Station] {
        return filterStations { $0.isFavorite }
    }
}

struct SearchOptions {
    enum Order: String {
        case byName
        case byVotes
        case byCountry
        case byBitrate
    }

    let allOrderTypes: [Order]

    var searchText: String = ""
    var isExactMatch: Bool = false
    var order: Order = .byName
}

protocol SearchableStationList: StationList {
    var searchOptions: SearchOptions { get set }

    func fetch()
    var fetchHandler: ((SearchableStationList) -> Void)? { get set }
}
