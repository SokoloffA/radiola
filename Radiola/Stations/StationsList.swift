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
//        func parent() -> Group? {
//            return root.find {
//                guard let group = $0 as? Group else { return false }
//                return group.nodes.contains(where: { $0.id == self.id })
//            } as? Group
//        }
}

/* ******************************************
 * Station
 * ******************************************/
class Station: StationNode {
    var url: String
    var isFavorite = false

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
    func index(_ node: StationNode) -> Int? {
        return nodes.firstIndex { $0.id == node.id }
    }
}

/* **********************************************
 * Station List
 * **********************************************/
class StationList: StationGroup {
    /* ******************************************
     *
     * ******************************************/
    enum State {
        case searchRequired
        case canLoad
        case loaded
    }

    let url: URL

    var state: State = .canLoad
    private(set) var isEditable = false

    /* ****************************************
     *
     * ****************************************/
    init(title: String, url: URL) {
        self.url = url
        super.init(title: title)
    }

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

    /* ****************************************
     *
     * ****************************************/
    func load() async {
        if url.isFileURL {
            loadLocal()
            isEditable = true
        } else {
            loadHttp()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func loadLocal() {
        print(url.path)

        if !FileManager().fileExists(atPath: url.path) {
            for s in defaultStations {
                nodes.append(s)
            }
            return
        }

        func getBoolAttribute(xml: XMLElement, attribute: String) -> Bool {
            return (xml.attribute(forName: attribute)?.stringValue ?? "").uppercased() == "TRUE"
        }

        func loadOutline(xml: XMLElement, parent: StationGroup) {
            let children = xml.elements(forName: "outline")

            if getBoolAttribute(xml: xml, attribute: "group") || !children.isEmpty {
                let group = StationGroup(title: xml.attribute(forName: "text")?.stringValue ?? "")

                for outline in children {
                    loadOutline(xml: outline, parent: group)
                }
                parent.nodes.append(group)
                return
            }

            let station = Station(
                title: xml.attribute(forName: "text")?.stringValue ?? "",
                url: xml.attribute(forName: "url")?.stringValue ?? "",
                isFavorite: getBoolAttribute(xml: xml, attribute: "fav")
            )
            parent.nodes.append(station)
        }

        do {
            let xml = try XMLDocument(contentsOf: url)
            guard let xmlRoot = xml.rootElement() else { return }
            let xmlBody = xmlRoot.elements(forName: "body")
            if xmlBody.isEmpty {
                return
            }

            for outline in xmlBody[0].elements(forName: "outline") {
                loadOutline(xml: outline, parent: self)
            }
        } catch {
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func loadHttp() {
    }

    /* ****************************************
     *
     * ****************************************/
    func write() {
    }
}
