//
//  LocalStationList.swift
//  Radiola
//
//  Created by Alex Sokolov on 21.05.2024.
//

import Foundation

// MARK: - LocalStationList

class LocalStationList: ObservableObject, StationList {
    let id = UUID()
    let title: String
    let icon: String
    let help: String?
    private(set) var file: URL?
    let root = LocalStationGroup(title: "")
    var items: [LocalStationItem] { return root.items }

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
        var queue = items

        while !queue.isEmpty {
            let item = queue.removeFirst()

            if let station = item as? LocalStation {
                if match(station) {
                    res.append(station)
                }
            }

            if let group = item as? LocalStationGroup {
                queue.insert(contentsOf: group.items, at: 0)
            }
        }

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    func firstItem(where predicate: (LocalStationItem) -> Bool) -> LocalStationItem? {
        var queue = root.items

        while !queue.isEmpty {
            let item = queue.removeFirst()

             if predicate(item) {
                  return item
              }

            if let group = item as? LocalStationGroup {
                queue += group.items
            }
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func firstStation(where predicate: (Station) -> Bool) -> Station? {
        var queue = root.items

        while !queue.isEmpty {
            let item = queue.removeFirst()

            if let station = item as? LocalStation {
                if predicate(station) {
                    return station
                }
            }

            if let group = item as? LocalStationGroup {
                queue += group.items
            }
        }

        return nil
    }



    /* ****************************************
     *
     * ****************************************/
    func firstGroup(where predicate: (LocalStationGroup) -> Bool) -> LocalStationGroup? {
        var queue = root.items

        while !queue.isEmpty {
            let item = queue.removeFirst()

            if let group = item as? LocalStationGroup {
                if predicate(group) {
                     return group
                 }

                queue += group.items
            }
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func item(byID: UUID) -> LocalStationItem? {
        var queue = root.items

        while !queue.isEmpty {
            let item = queue.removeFirst()

            if item.id == byID {
                return item
            }

            if let group = item as? LocalStationGroup {
                queue += group.items
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

    /* ****************************************
     *
     * ****************************************/
    func walk(handler: (LocalStationItem) -> Void) {
        var queue = root.items

        while !queue.isEmpty {
            let item = queue.removeFirst()

            handler(item)

            if let group = item as? LocalStationGroup {
                queue += group.items
            }
        }
    }

}



extension LocalStationList {


    /* ****************************************
     *
     * ****************************************/
    func load(file: URL, defaultStations: [LocalStation] = []) {
        self.file = file

        do {
            try load(file: file)
        }
        catch {
            for s in defaultStations {
                append(s)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func load(file: URL) throws {
        self.file = file

        if !FileManager().fileExists(atPath: file.path) {
            throw Alarm(title: "Can't read the stations file", message: "File doesn't exist")
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
            throw Alarm(title: "Can't read the stations file", message: "The file is corrupted or has an incorrect format", parentError: error)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func save() {
        do {
            guard let file = file else { return }
            try saveAs(file: file)
        } catch {
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func saveAs(file: URL) throws {
        do {
            let document = asXML()
            let xmlData = document.xmlData(options: .nodePrettyPrint)
            try xmlData.write(to: file)
        } catch {
            throw Alarm(title: "Can't write the stations file '\(file.absoluteString)'", message: "The file is corrupted or has an incorrect format", parentError: error)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func asXML() -> XMLDocument {
        func writeOutline(parent: XMLElement, item: LocalStationItem) {
            let outline = XMLElement(name: "outline")
            outline.addAttribute(XMLNode.attribute(withName: "text", stringValue: item.title) as! XMLNode)

            if let station = item as? LocalStation {
                outline.addAttribute(XMLNode.attribute(withName: "url", stringValue: station.url) as! XMLNode)
                if station.isFavorite {
                    outline.addAttribute(XMLNode.attribute(withName: "fav", stringValue: "true") as! XMLNode)
                }
            }

            if let group = item as? LocalStationGroup {
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

        return XMLDocument(rootElement: ompl)
    }

    /* ****************************************
     *
     * ****************************************/
    func dump() {
        func dump(_ item: LocalStationItem, indent: String) {
            if let station = item as? LocalStation {
                print("\(indent)○ [\(station.id)] \(station.title) \(station.url)")
                return
            }

            if let group = item as? LocalStationGroup {
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

//MARK: - extension [LocalStationList]

extension [LocalStationList] {
    func find(byId: UUID) -> LocalStationList? {
        return first { $0.id == byId }
    }
}
