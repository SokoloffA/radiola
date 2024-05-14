//
//  LocalStations.swift
//  Radiola
//
//  Created by Alex Sokolov on 10.12.2023.
//

import Foundation

// MARK: - LocalStation

class LocalStation: ObservableObject, Station {
    var id = UUID()
    @Published var title: String
    @Published var url: String
    @Published var isFavorite: Bool
    weak var parent: LocalStationGroup?

    /* ****************************************
     *
     * ****************************************/
    init(title: String, url: String, isFavorite: Bool = false) {
        self.title = title
        self.url = url
        self.isFavorite = isFavorite
    }
}

// MARK: - LocalStationGroup

class LocalStationGroup: ObservableObject {
    let id = UUID()
    var title: String
    var items: [Item] = [] {
        didSet {
            for i in items.indices {
                items[i].parent = self
            }
        }
    }

    weak var parent: LocalStationGroup?

    typealias Item = LocalStationList.Item

    /* ****************************************
     *
     * ****************************************/
    init(title: String, items: [Item] = []) {
        self.title = title
        self.items = items
    }

    /* ****************************************
     *
     * ****************************************/
    func append(_ item: Item) {
        items.append(item)
    }

    /* ****************************************
     *
     * ****************************************/
    func append(_ station: LocalStation) {
        items.append(Item.station(station: station))
    }

    /* ****************************************
     *
     * ****************************************/
    func append(_ group: LocalStationGroup) {
        items.append(Item.group(group: group))
    }

    /* ****************************************
     *
     * ****************************************/
    func insert(_ item: Item, afterId: UUID) {
        let index = items.firstIndex { $0.id == afterId }

        if let index = index {
            if index < items.count - 1 {
                items.insert(item, at: index + 1)
            } else {
                append(item)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func index(_ itemId: UUID) -> Int? {
        return items.firstIndex { $0.id == itemId }
    }
}

// MARK: - LocalStationList.Item

extension LocalStationList {
    enum Item: Identifiable {
        case station(station: LocalStation)
        case group(group: LocalStationGroup)

        /* ****************************************
         *
         * ****************************************/
        var id: UUID {
            switch self {
                case let .station(station: station): return station.id
                case let .group(group: group): return group.id
            }
        }

        /* ****************************************
         *
         * ****************************************/
        var title: String {
            switch self {
                case let .station(station: station): return station.title
                case let .group(group: group): return group.title
            }
        }

        /* ****************************************
         *
         * ****************************************/
        var items: [Item]? {
            switch self {
                case .station(_: _): return nil
                case let .group(group: group): return group.items
            }
        }

        /* ****************************************
         *
         * ****************************************/
        var parent: LocalStationGroup? {
            get {
                switch self {
                    case let .station(station: station): return station.parent
                    case let .group(group: group): return group.parent
                }
            }

            set {
                switch self {
                    case let .station(station: station): return station.parent = newValue
                    case let .group(group: group): return group.parent = newValue
                }
            }
        }

        /* ****************************************
         *
         * ****************************************/
        var isStation: Bool {
            switch self {
                case .station: return true
                case .group: return false
            }
        }

        /* ****************************************
         *
         * ****************************************/
        var isGroup: Bool {
            switch self {
                case .station: return false
                case .group: return true
            }
        }
    } // Item
}

// MARK: - LocalStationList

class LocalStationList: ObservableObject, StationList {
    let id = UUID()
    let title: String
    let icon: String
    let help: String?
    private(set) var file: URL?
    let root = LocalStationGroup(title: "")
    var items: [Item] { return root.items }

    /* ****************************************
     *
     * ****************************************/
    init(title: String, icon: String, help: String? = nil) {
        self.title = title
        self.icon = icon
        self.help = help
    }

    /* ****************************************
     *
     * ****************************************/
    func favoritesStations() -> [Station] {
        return filterStations { $0.isFavorite }
    }

    /* ****************************************
     *
     * ****************************************/
    private func filterStations(where match: (LocalStation) -> Bool) -> [Station] {
        var res: [Station] = []
        var queue: [Item] = items

        while !queue.isEmpty {
            let item = queue.removeFirst()

            switch item {
                case let .station(station: station):
                    if match(station) {
                        res.append(station)
                    }

                case let .group(group: group):
                    queue.insert(contentsOf: group.items, at: 0)
            }
        }

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    func first(where predicate: (Station) -> Bool) -> Station? {
        var queue: [Item] = root.items

        while !queue.isEmpty {
            let item = queue.removeFirst()

            switch item {
                case let .station(station: station):
                    if predicate(station) {
                        return station
                    }

                case let .group(group: group):
                    queue += group.items
            }
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func item(byID: UUID) -> Item? {
        var queue: [Item] = root.items

        while !queue.isEmpty {
            let item = queue.removeFirst()
            if item.id == byID {
                return item
            }

            switch item {
                case let .group(group: group): queue += group.items
                default: break
            }
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func append(_ station: LocalStation) {
        root.append(station)
    }

    /* ****************************************
     *
     * ****************************************/
    func append(_ group: LocalStationGroup) {
        root.append(group)
    }
}

extension [LocalStationList] {
    func find(byId: UUID) -> LocalStationList? {
        return first { $0.id == byId }
    }
}

extension LocalStationList {
    /* ****************************************
     *
     * ****************************************/
    func load(file: URL, defaultStations: [LocalStation] = []) {
        self.file = file
        // print(file.path)

        if !FileManager().fileExists(atPath: file.path) {
            for s in defaultStations {
                root.append(s)
            }
            return
        }

        func getBoolAttribute(xml: XMLElement, attribute: String) -> Bool {
            return (xml.attribute(forName: attribute)?.stringValue ?? "").uppercased() == "TRUE"
        }

        func loadOutline(xml: XMLElement, parent: LocalStationGroup) {
            let children = xml.elements(forName: "outline")

            if getBoolAttribute(xml: xml, attribute: "group") || !children.isEmpty {
                let group = LocalStationGroup(title: xml.attribute(forName: "text")?.stringValue ?? "")

                for outline in children {
                    loadOutline(xml: outline, parent: group)
                }
                parent.append(group)
                return
            }

            parent.append(LocalStation(
                title: xml.attribute(forName: "text")?.stringValue ?? "",
                url: xml.attribute(forName: "url")?.stringValue ?? "",
                isFavorite: getBoolAttribute(xml: xml, attribute: "fav")
            ))
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
    func save() {
        guard let file = file else { return }
        saveAs(file: file)
    }

    /* ****************************************
     *
     * ****************************************/
    func saveAs(file: URL) {
        func writeOutline(parent: XMLElement, item: Item) {
            let outline = XMLElement(name: "outline")
            outline.addAttribute(XMLNode.attribute(withName: "text", stringValue: item.title) as! XMLNode)

            switch item {
                case let .station(station: station):
                    outline.addAttribute(XMLNode.attribute(withName: "url", stringValue: station.url) as! XMLNode)
                    if station.isFavorite {
                        outline.addAttribute(XMLNode.attribute(withName: "fav", stringValue: "true") as! XMLNode)
                    }

                case let .group(group: group):
                    outline.addAttribute(XMLNode.attribute(withName: "group", stringValue: "true") as! XMLNode)
                    for it in group.items {
                        writeOutline(parent: outline, item: it)
                    }
            }

            parent.addChild(outline)
        }

        let ompl = XMLElement(name: "ompl")
        ompl.addAttribute(XMLNode.attribute(withName: "version", stringValue: "2.0") as! XMLNode)
        ompl.addChild(XMLElement(name: "head"))
        let body = XMLElement(name: "body")
        ompl.addChild(body)

        for item in root.items {
            writeOutline(parent: body, item: item)
        }

        do {
            let document = XMLDocument(rootElement: ompl)
            let xmlData = document.xmlData(options: .nodePrettyPrint)
            try xmlData.write(to: file)
        } catch {
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func dump() {
        func dump(_ item: Item, indent: String) {
            switch item {
                case let .station(station: station):
                    print("\(indent)○ [\(station.id)] \(station.title) \(station.url)")
                    return

                case let .group(group: group):
                    print("\(indent)▼ [\(group.id)] \(group.title)")

                    for item in group.items {
                        dump(item, indent: "  " + indent)
                    }
            }
        }

        for item in root.items {
            dump(item, indent: "")
        }
    }
}
