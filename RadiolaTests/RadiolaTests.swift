//
//  RadiolaTests.swift
//  RadiolaTests
//
//  Created by Alex Sokolov on 21.05.2024.
//

@testable import Radiola
import XCTest

final class RadiolaTests: XCTestCase {
    /* ****************************************
     *
     * ****************************************/
    func dataDir(testName: String) -> URL {
        let url = URL(fileURLWithPath: #file)
        let testsDir = url.deletingLastPathComponent()
        var res = testsDir.appendingPathComponent("data")

        if testName.hasSuffix("()") {
            res = res.appendingPathComponent(String(testName.dropLast(2)))
        } else {
            res = res.appendingPathComponent(testName)
        }

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    func walkDataDir(testName: String, handler: (URL) throws -> Void) throws {
        let dir = dataDir(testName: testName)
        let dirs = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter(\.hasDirectoryPath).sorted{ $0.path() < $1.path() }

        for d in dirs {
            try handler(d)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    /* ****************************************
     *
     * ****************************************/
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}
