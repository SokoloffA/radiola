//
//  RadiolaTests.swift
//  RadiolaTests
//
//  Created by Alex Sokolov on 21.05.2024.
//

@testable import Radiola
import XCTest

enum RadiolaTestsError: Error, LocalizedError {
    case directoryNotFound(URL)
    case fileNotFound
    case multipleFilesFound([URL])

    var errorDescription: String? {
        switch self {
        case .directoryNotFound(let url):
            return "Directory not found: \(url.path)"

        case .fileNotFound:
            return "File 'source' with any extension not found"

        case .multipleFilesFound(let urls):
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
        let dirs = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter(\.hasDirectoryPath).sorted{ $0.path() < $1.path() }

        for d in dirs {
            try handler(d)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func findFile(name: String,  in directory: URL) throws -> URL {
        let fileManager = FileManager.default

        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        let files = contents.filter { url in
            url.deletingPathExtension().lastPathComponent == name
        }

        guard !files.isEmpty else {
                throw RadiolaTestsError.fileNotFound
            }

            guard files.count == 1 else {
                throw RadiolaTestsError.multipleFilesFound(files)
            }

        return files[0]
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

        return (0..<Int(globResult.gl_matchc)).compactMap { index in
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
        return try readLines(from: url).map {  URL(string: $0, relativeTo: relativeTo)}
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
