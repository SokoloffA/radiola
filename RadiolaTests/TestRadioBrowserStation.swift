//
//  TestRadioBrowserStation.swift
//  RadiolaTests
//
//  Created by Aleksandr Sokolov on 14.07.2026.
//

import Foundation

@testable import Radiola
import XCTest

extension RadiolaTests {
    /* ****************************************
     *
     * ****************************************/
    func testRadioBrowserStationInit() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.iso8601

        try walkDataFiles(testName: #function, pattern: "*.json") { file in
            let data = try Data(contentsOf: file)
            _ = try decoder.decode(RadioBrowser.Station.self, from: data)
        }
    }
}
