//
//  RadioBrowser.swift
//  Radiola
//
//  Created by Alex Sokolov on 28.08.2023.
//

import Foundation

enum RadioBrowser {}

extension RadioBrowser {
    public struct Error: LocalizedError {
        public var errorDescription: String?
        public var failureReason: String?
        public var recoverySuggestion: String?

        init(_ description: String, failureReason: String? = nil) {
            errorDescription = description
            self.failureReason = failureReason
        }
    }
}
