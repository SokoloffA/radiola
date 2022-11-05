//
//  Stations.swift
//  Radiola
//
//  Created by Alex Sokolov on 26.05.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import Foundation

/* ****************************************
 *
 * ****************************************/
class Station: StationsStore.Node {
    var url: String
    var isFavorite = false

    /* ****************************************
     *
     * ****************************************/
    init(name: String, url: String, isFavorite: Bool = false) {
        self.url = url
        self.isFavorite = isFavorite
        super.init()
        self.name = name
    }

    /* ****************************************
     *
     * ****************************************/
    var isEmpty: Bool {
        return url.isEmpty
    }
}

/* ****************************************
 *
 * ****************************************/
class Group: StationsStore.Node {
    var nodes: [StationsStore.Node] = []

    /* ****************************************
     *
     * ****************************************/
    init(name: String) {
        super.init()
        self.name = name
    }

    /* ****************************************
     *
     * ****************************************/
    func find(where f: (StationsStore.Node) -> Bool) -> StationsStore.Node? {
        var queue: [StationsStore.Node] = [self]

        while !queue.isEmpty {
            let n = queue.removeFirst()

            if f(n) {
                return n
            }

            if let g = n as? Group {
                queue += g.nodes
            }
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func append(_ node: StationsStore.Node) {
        nodes.append(node)
    }

    /* ****************************************
     *
     * ****************************************/
    func insert(_ node: StationsStore.Node, at: Int) {
        nodes.insert(node, at: at)
    }

    /* ****************************************
     *
     * ****************************************/
    func insert(_ node: StationsStore.Node, after: StationsStore.Node) {
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
    func remove(_ node: StationsStore.Node) {
        let index = nodes.firstIndex { $0.id == node.id }

        if let index = index {
            nodes.remove(at: index)
        }
    }
}

/* ****************************************
 *
 * ****************************************/
private let defaultStations: [Station] = [
    Station(
        name: "Radio Caroline",
        url: "http://sc3.radiocaroline.net:8030",
        isFavorite: true
    ),

    Station(
        name: "Radio Caroline 319 Gold [ Hits from '60-'70 ]",
        url: "http://www.rcgoldserver.eu:8192",
        isFavorite: true
    ),

    Station(
        name: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]",
        url: "http://www.rcgoldserver.eu:8253",
        isFavorite: true
    ),
]

/* ****************************************
 *
 * ****************************************/
class StationsStore {
    public var root = Group(name: "")
    var file: URL?

    class Node {
        private static var lastId = 0
        let id: Int = { lastId += 1; return lastId }()
        var name: String = ""

        /* ****************************************
         *
         * ****************************************/
        func parent() -> Group? {
            return stationsStore.root.find {
                guard let group = $0 as? Group else { return false }
                return group.nodes.contains(where: { $0.id == self.id })
            } as? Group
        }
    }

    func loadFake() {
        let s = Station(
            name: "First station",
            url: "https://first_radio.com"
        )
        root.nodes.append(s)

        let g = Group(name: "Super Group")
        root.nodes.append(g)

        for i in 1 ... 5 {
            g.nodes.append(Station(
                name: "Station \(i)",
                url: "https://radio-\(i).com"
            ))
        }

//        print("-=-=-=-=-=-=-=-=-=-=-=-=-=-")
//        print(s.parent()?.id)
//        print("-=-=-=-=-=-=-=-=-=-=-=-=-=-")
//        dump()
    }

    /* ****************************************
     *
     * ****************************************/
    func load(file: URL) {
//        print(file)
        self.file = file

        // return loadFake()

        if !FileManager().fileExists(atPath: file.path) {
            for s in defaultStations {
                root.nodes.append(s)
            }
            return
        }

        func loadOutline(xml: XMLElement, parent: Group) {
            let children = xml.elements(forName: "outline")
            if !children.isEmpty {
                let group = Group(name: xml.attribute(forName: "text")?.stringValue ?? "")

                for outline in children {
                    loadOutline(xml: outline, parent: group)
                }
                parent.nodes.append(group)
            }

            let station = Station(
                name: xml.attribute(forName: "text")?.stringValue ?? "",
                url: xml.attribute(forName: "url")?.stringValue ?? "",
                isFavorite: (xml.attribute(forName: "fav")?.stringValue ?? "") == "True"
            )

            parent.nodes.append(station)
        }

        do {
            let xml = try XMLDocument(contentsOf: file)
            guard let xmlRoot = xml.rootElement() else { return }
            let xmlBody = xmlRoot.elements(forName: "body")
            if xmlBody.isEmpty {
                return
            }

            for outline in xmlBody[0].elements(forName: "outline") {
                loadOutline(xml: outline, parent: root)
            }
        } catch {
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func write() {
//         if file != nil {
//            let writer = Writer()
//            do {
//                try writer.write(file: self.file!, stations: stations)
//            }
//            catch {
//                fatalError(error.localizedDescription)
//            }
//        }
    }

    /* ****************************************
     *
     * ****************************************/
    func dump() {
        func dump(node: Node, indent: String) {
            if let s = node as? Station {
                print("\(indent)○ [\(s.id)] \(s.name) \(s.url)")
                return
            }

            if let g = node as? Group {
                print("\(indent)▼ [\(g.id)] \(g.name)")

                for n in g.nodes {
                    dump(node: n, indent: "  " + indent)
                }
            }
        }

        for node in root.nodes {
            dump(node: node, indent: "")
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func emitChanged() {
        NotificationCenter.default.post(
            name: Notification.Name.StationsChanged,
            object: nil)
    }

    /* ****************************************
     *
         * ****************************************/
    func find(byId: Int) -> Node? {
        return find { $0.id == byId }
    }

    /* ****************************************
     *
     * ****************************************/
    func find(where f: (Node) -> Bool) -> Node? {
        return root.find(where: f)
    }

    /* ****************************************
     *
     * ****************************************/
    private func filterStations(where f: (Station) -> Bool) -> [Station] {
        var res: [Station] = []
        var queue: [Node] = root.nodes

        while !queue.isEmpty {
            let node = queue[0]
            queue.removeFirst()

            if let station = node as? Station {
                if f(station) { res.append(station) }
            } else if let group = node as? Group {
                queue += group.nodes
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

    /* ****************************************
     *
     * ****************************************/
    func station(byId: Int) -> Station? {
        return find(byId: byId) as? Station
    }

    /* ****************************************
     *
     * ****************************************/
    func station(byUrl: String) -> Station? {
        return find { ($0 as? Station)?.url == byUrl } as? Station
    }
}

var stationsStore = StationsStore()
