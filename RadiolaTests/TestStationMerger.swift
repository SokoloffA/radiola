//
//  TestStationMerger.swift
//  RadiolaTests
//
//  Created by Alex Sokolov on 21.05.2024.
//

@testable import Radiola
import XCTest

extension RadiolaTests {
    /* ****************************************
     *
     * ****************************************/
    func testStationMerger() throws {
        try walkDataDir(testName: #function) { dir in

            let cur = OpmlStations(title: "CUR", icon: "")
            try cur.load(file: dir.appendingPathComponent("current.opml"))

            let new = OpmlStations(title: "NEW", icon: "")
            try new.load(file: dir.appendingPathComponent("new.opml"))

            let expected = OpmlStations(title: "Expected", icon: "")
            try expected.load(file: dir.appendingPathComponent("result.opml"))

            let merger = StationsMerger(currentStations: cur, newStations: new)
            merger.run()

            // print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
            // print("INS: \(merger.statisics)")
            // merger.currentStations.dump()
            // print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
            XCTAssertEqual(cur.asXML(), expected.asXML(), "\nFAILED TEST \(dir.path().removingPercentEncoding ?? "")\n")
        }
    }
}
