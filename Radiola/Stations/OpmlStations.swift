//
//  OpmlStations.swift
//  Radiola
//
//  Created by Alex Sokolov on 25.08.2024.
//

import Foundation

fileprivate let oplDirectoryName = "com.github.SokoloffA.Radiola/"

// MARK: - OpmlStation

class OpmlStation: Station {
    var id: UUID = UUID()
    var title: String
    var url: String
    var isFavorite: Bool

    init(title: String, url: String, isFavorite: Bool = false) {
        self.title = title
        self.url = url
        self.isFavorite = isFavorite
    }
}

// MARK: - OpmlGroup

class OpmlGroup: StationGroup {
    var id: UUID = UUID()
    var title: String
    var items: [any StationItem] = []

    init(title: String) {
        self.title = title
    }
}

// MARK: - OpmlStations

class OpmlStations: StationList {
    let id = UUID()
    var title: String
    var icon: String
    var items: [any StationItem] = []
    let file: URL

    /* ****************************************
     *
     * ****************************************/
    init(title: String, icon: String, file: URL) {
        self.file = file
        self.title = title
        self.icon = icon
    }

    /* ****************************************
     *
     * ****************************************/
    func createStation(title: String, url: String) -> any Station {
        return OpmlStation(title: title, url: url)
    }

    /* ****************************************
     *
     * ****************************************/
    func createGroup(title: String) -> any StationGroup {
        return OpmlGroup(title: title)
    }

    /* ****************************************
     *
     * ****************************************/
    func load(defaultStations: [Station] = []) {
        do {
            try load()
        } catch {
            for s in defaultStations {
                append(s)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func load() throws {
        if !FileManager().fileExists(atPath: file.path) {
            throw Alarm(title: "Can't read the stations file", message: "File doesn't exist")
        }

        func getBoolAttribute(xml: XMLElement, attribute: String) -> Bool {
            return (xml.attribute(forName: attribute)?.stringValue ?? "").uppercased() == "TRUE"
        }

        func loadOutline(xml: XMLElement, parent: StationGroup) {
            let children = xml.elements(forName: "outline")

            if getBoolAttribute(xml: xml, attribute: "group") || !children.isEmpty {
                let group = OpmlGroup(title: xml.attribute(forName: "text")?.stringValue ?? "")

                for outline in children {
                    loadOutline(xml: outline, parent: group)
                }
                parent.append(group)
                return
            }

            parent.append(OpmlStation(
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

            let root = OpmlGroup(title: "")
            for outline in xmlBody[0].elements(forName: "outline") {
                loadOutline(xml: outline, parent: root)
            }
            items = root.items
        } catch {
            throw Alarm(title: "Can't read the stations file", message: "The file is corrupted or has an incorrect format", parentError: error)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func save() {
        do {
            try saveAsOpml(file: file)
        } catch {
        }
    }
}

extension StationList {
    /* ****************************************
     *
     * ****************************************/
    func saveAsOpml(file: URL) throws {
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
        func writeOutline(parent: XMLElement, item: StationItem) {
            let outline = XMLElement(name: "outline")
            outline.addAttribute(XMLNode.attribute(withName: "text", stringValue: item.title) as! XMLNode)

            if let station = item as? Station {
                outline.addAttribute(XMLNode.attribute(withName: "url", stringValue: station.url) as! XMLNode)
                if station.isFavorite {
                    outline.addAttribute(XMLNode.attribute(withName: "fav", stringValue: "true") as! XMLNode)
                }
            }

            if let group = item as? StationGroup {
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

        for item in items {
            writeOutline(parent: body, item: item)
        }

        return XMLDocument(rootElement: ompl)
    }
}
