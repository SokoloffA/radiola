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

            let cur = OpmlStations(title: "CUR", icon: "", file: dir.appendingPathComponent("current.opml"))
            try cur.load()

            let new = OpmlStations(title: "NEW", icon: "", file: dir.appendingPathComponent("new.opml"))
            try new.load()

            let expected = OpmlStations(title: "Expected", icon: "", file: dir.appendingPathComponent("result.opml"))
            try expected.load()

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
