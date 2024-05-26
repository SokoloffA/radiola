//
//  TestTrackMetadata.swift
//  RadiolaTests
//
//  Created by Alex Sokolov on 26.05.2024.
//

@testable import Radiola
import XCTest

extension RadiolaTests {
    /* ****************************************
     *
     * ****************************************/
    func testTrackMetadata() throws {
        let cases: [(String, String)] = [
            (
                input: "",
                expected: ""
            ),

            (
                input: "The Beatles - Let it be",
                expected: "The Beatles - Let it be"
            ),

            (
                input: #"{"artist":"The Beatles","duration":"00:02:53","name":"Let it be","type":"М"}"#,
                expected: "The Beatles - Let it be"
            ),
        ]

        for (input, expected) in cases {
            let actual = cleanTrackMetadata(raw: input)
            XCTAssertEqual(actual, expected)
        }
    }
}
