//
//  RadioBrowser.swift
//  Radiola
//
//  Created by Alex Sokolov on 28.08.2023.
//

import Foundation

enum RadioBrowser {
    public enum Error: Swift.Error {
        case dnsError
        case invalidURL
        case missingData
    }
}
