//
//  RadiolaTests.swift
//  RadiolaTests
//
//  Created by Alex Sokolov on 21.05.2024.
//

import Darwin
@testable import Radiola
import XCTest

enum RadiolaTestsError: Error, LocalizedError {
    case directoryNotFound(URL)
    case fileNotFound
    case multipleFilesFound([URL])

    var errorDescription: String? {
        switch self {
            case let .directoryNotFound(url):
                return "Directory not found: \(url.path)"

            case .fileNotFound:
                return "File 'source' with any extension not found"

            case let .multipleFilesFound(urls):
                return "Multiple files named 'source' found: \(urls.map { $0.lastPathComponent })"
        }
    }
}

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
        let dirs = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter(\.hasDirectoryPath).sorted { $0.path() < $1.path() }

        for d in dirs {
            try handler(d)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func findFiles(pattern: String) -> [String] {
        var globBuffer = glob_t()
        let result = Darwin.glob(pattern, 0, nil, &globBuffer)
        defer { globfree(&globBuffer) }
        guard result == 0, let pathCount = globBuffer.gl_pathc as Int?, pathCount > 0 else {
            return []
        }

        var files: [String] = []
        for i in 0 ..< pathCount {
            if let pathCStr = globBuffer.gl_pathv[i] {
                let path = String(cString: pathCStr)
                files.append(path)
            }
        }

        return files
    }

    /* ****************************************
     *
     * ****************************************/
    func findFiles(pattern: String, in dir: URL) -> [String] {
        let p = URL(fileURLWithPath: dir.path).appendingPathComponent(pattern).path
        return findFiles(pattern: p)
    }

    /* ****************************************
     *
     * ****************************************/
    func findFile(pattern: String, in directory: URL) throws -> URL {
        guard
            let s = findFiles(pattern: pattern, in: directory).first
        else {
            throw RadiolaTestsError.fileNotFound
        }

        return URL(fileURLWithPath: s)
    }

    /* ****************************************
     *
     * ****************************************/
    func glob(pattern: String) throws -> [URL] {
        var globResult = glob_t()

        let flags = GLOB_TILDE
        let result = pattern.withCString {
            Darwin.glob($0, flags, nil, &globResult)
        }

        guard result == 0 else {
            throw NSError(domain: "GlobError", code: Int(result))
        }

        defer { Darwin.globfree(&globResult) }

        return (0 ..< Int(globResult.gl_matchc)).compactMap { index in
            guard let path = globResult.gl_pathv[index] else { return nil }
            return URL(fileURLWithPath: String(cString: path))
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func readLines(from url: URL) throws -> [String] {
        let content = try String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        return content.components(separatedBy: .newlines)
    }

    /* ****************************************
     *
     * ****************************************/
    func readURLs(from url: URL, relativeTo: URL? = nil) throws -> [URL?] {
        return try readLines(from: url).map { URL(string: $0, relativeTo: relativeTo) }
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

    /* ****************************************
     *
     * ****************************************/
    func loadJSON<T: Decodable>(_ fileName: String, in directory: URL) throws -> T {
        let f = try findFile(pattern: fileName, in: directory)
        let data = try Data(contentsOf: f)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(T.self, from: data)
    }
}
