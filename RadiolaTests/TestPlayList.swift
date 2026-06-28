//
//  TestPlayList.swift
//  RadiolaTests
//
//  Created by Alex Sokolov on 14.02.2026.
//

@testable import Radiola
import XCTest

extension RadiolaTests {
    /* ****************************************
     *
     * ****************************************/
    func testPlayListDownload() throws {
        try walkDataDir(testName: #function) { dir in

            let sourceFile = try findFile(pattern: "source.*", in: dir)
            let expected = try readURLs(from: sourceFile, relativeTo: sourceFile)

            let playList = PlayList()
            try playList.download(url: sourceFile)

            XCTAssertEqual(playList.urls, expected, "\nFAILED TEST \(dir.path().removingPercentEncoding ?? "")\n")
        }
    }
}

extension RadiolaTests {
    /* ****************************************
     *
     * ****************************************/
    func testPlayListTitles() throws {
        try walkDataDir(testName: #function) { dir in

            let sourceFile = try findFile(pattern: "source.*", in: dir)
            let expected = try loadJSON("expected.json", in: dir) as [String]

            let playList = PlayList()
            try playList.download(url: sourceFile)

            let titles = playList.links.compactMap { $0.title ?? "" }
            XCTAssertEqual(titles, expected, "\nFAILED TEST \(dir.path().removingPercentEncoding ?? "")\n")
        }
    }
}
