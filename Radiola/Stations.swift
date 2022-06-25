//
//  Stations.swift
//  Radiola
//
//  Created by Alex Sokolov on 26.05.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import Foundation

struct Station: Hashable, Codable, Identifiable {
    var id: Int
    var name : String
    var url  : String
    
    var isFavorite = false
    
    var isEmpty: Bool {
        return url.isEmpty
    }
}

let defaultStations: [Station] = [
    Station(
        id: 1,
        name: "Radio Caroline",
        url: "http://sc3.radiocaroline.net:8030",
        isFavorite: true
    ),
           
    Station(
        id: 2,
        name: "Radio Caroline 319 Gold [ Hits from '60-'70 ]",
        url: "http://www.rcgoldserver.eu:8192",
        isFavorite: true
    ),
           
    Station(
        id: 3,
        name: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]",
        url: "http://www.rcgoldserver.eu:8253",
        isFavorite: true
    ),
]

private class Reader: NSObject, XMLParserDelegate {
    var stations: [Station] = []

    func load(file: URL) -> [Station] {
        let parser = XMLParser(contentsOf: file)!
        let reader = self
        parser.delegate = reader
        if parser.parse()  {
            return stations
        }
        else {
            //print("Parse OPML file error on line \(parser.line\) and column \(parser.column\): \(parser.parserError ?? ""\)")
            return []
        }
    }

    
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String]) {

        if elementName != "outline" || attributeDict["url"] == nil {
            return
        }
        
        let station = Station(
            id:         stations.count,
            name:       attributeDict["text"] ?? "",
            url:        attributeDict["url"]  ?? "",
            isFavorite: (attributeDict["fav"] ?? "") == "True"
        )
        stations.append(station)
    }
}

private class Writer {
    func write(file: URL, stations: [Station]) throws {
        let root = XMLElement(name: "opml")
        root.setAttributesAs(["version" : "2.0"])
        let doc = XMLDocument(rootElement: root)
        root.addChild(XMLElement(name: "head"))
        let body = XMLElement(name: "body")
        root.addChild(body)
        for station in stations {
            let outline = XMLElement(name: "outline")
            outline.setAttributesAs([
                "text": station.name,
                "url": station.url,
                "fav": (station.isFavorite ? "True" : "False"),
            ])
            body.addChild(outline)
        }
        
        try doc.xmlData(options: XMLNode.Options.nodePrettyPrint).write(to: file)
    }
    
}



final class StationsStore: ObservableObject {
    @Published var stations: [Station] = [] //allStations
    var file: URL?
    
    func load(file: URL) {
        self.file = file
        if !FileManager().fileExists(atPath: file.path)
        {
            stations = defaultStations
            return
        }
        stations = Reader().load(file: file)
    }

    func write() {
        if file != nil {
            let writer = Writer()
            do {
                try writer.write(file: self.file!, stations: stations)
            }
            catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    func favorites() -> [Station] {
        return self.stations.filter{$0.isFavorite}
    }
    
    func station(byId: Int) -> Station? {
        return self.stations.first{$0.id == byId}
    }
    
    func station(byUrl: String) -> Station? {
        return self.stations.first{$0.url == byUrl}
    }
}

var stationsStore = StationsStore()
