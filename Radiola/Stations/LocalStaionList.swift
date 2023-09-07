//
//  LocalStaionList.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 06.09.2023.
//

import Foundation

class LocalStationList: StationList {
    private(set) var file: URL?
    override var isEditable: Bool { return true }

    /* ****************************************
     *
     * ****************************************/
    func load(file: URL, defaultStations: [Station] = []) {
        self.file = file
        // print(file.path)

        if !FileManager().fileExists(atPath: file.path) {
            for s in defaultStations {
                append(s)
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
            let xml = try XMLDocument(contentsOf: file)
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
    func save() {
        guard let file = file else { return }

        func writeOutline(parent: XMLElement, node: StationNode) {
            let outline = XMLElement(name: "outline")
            outline.addAttribute(XMLNode.attribute(withName: "text", stringValue: node.title) as! XMLNode)

            if let station = node as? Station {
                outline.addAttribute(XMLNode.attribute(withName: "url", stringValue: station.url) as! XMLNode)
                if station.isFavorite {
                    outline.addAttribute(XMLNode.attribute(withName: "fav", stringValue: "true") as! XMLNode)
                }
            }

            if let group = node as? StationGroup {
                outline.addAttribute(XMLNode.attribute(withName: "group", stringValue: "true") as! XMLNode)
                for n in group.nodes {
                    writeOutline(parent: outline, node: n)
                }
            }

            parent.addChild(outline)
        }

        let ompl = XMLElement(name: "ompl")
        ompl.addAttribute(XMLNode.attribute(withName: "version", stringValue: "2.0") as! XMLNode)
        ompl.addChild(XMLElement(name: "head"))
        let body = XMLElement(name: "body")
        ompl.addChild(body)

        for node in nodes {
            writeOutline(parent: body, node: node)
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
        func dump(node: StationNode, indent: String) {
            if let s = node as? Station {
                print("\(indent)○ [\(s.id)] \(s.title) \(s.url)")
                return
            }

            if let g = node as? StationGroup {
                print("\(indent)▼ [\(g.id)] \(g.title)")

                for n in g.nodes {
                    dump(node: n, indent: "  " + indent)
                }
            }
        }

        for node in nodes {
            dump(node: node, indent: "")
        }
    }
}
