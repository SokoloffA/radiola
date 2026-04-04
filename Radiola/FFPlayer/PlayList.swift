//
//  PlayList.swift
//  Radiola
//
//  Created by Alex Sokolov on 29.06.2025.
//

import Foundation

extension PlayList {
    enum Format: String {
        case hls = "m3u8"
        case pls
        case m3u
        case asx
        case xspf
    }
}

class PlayList {
    private(set) var urls: [URL] = []

    /* ****************************************
     *
     * ****************************************/
    static func isPlayListURL(_ url: URL) -> Bool {
        return Format(rawValue: url.pathExtension.lowercased()) != nil
    }

    /* ****************************************
     *
     * ****************************************/
    func download(url: URL) throws {
        let semaphore = DispatchSemaphore(value: 0)
        var error: NSError?

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let task = URLSession.shared.dataTask(with: request) { data, _, err in
            defer { semaphore.signal() }

            if let err = err {
                error = NSError(code: .playlistDownloadError, message: err.localizedDescription, debug: "Unable to download playlist \(err)")
                return
            }

            guard let data = data else {
                error = NSError(code: .playlistEmptyResponse, message: invalidURLErrorDescription, debug: "Unable to download playlist: empty response")
                return
            }

            guard let content = String(data: data, encoding: .utf8) else {
                error = NSError(code: .playlistInvalidData, message: invalidURLErrorDescription, debug: "Unable to parse playlist: invalid data")
                return
            }

            guard let format = Format(rawValue: url.pathExtension.lowercased()) else {
                self.urls = [url]
                return
            }

            switch format {
                case .hls: self.urls = [url]
                case .m3u: self.urls = self.parseM3u(baseURL: url, content: content)
                case .pls: self.urls = self.parsePls(baseURL: url, content: content)
                case .asx: self.urls = self.parseAsx(baseURL: url, content: content)
                case .xspf: self.urls = self.parseXspf(baseURL: url, content: content)
            }
        }
        task.resume()
        semaphore.wait()

        if let error = error {
            throw error
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func getFormat(_ content: String) -> Format? {
        let lowered = content.lowercased()

        if lowered.contains("#ext-x-") { return .hls }
        if lowered.contains("#extm3u") { return .m3u }
        if lowered.contains("[playlist]") { return .pls }
        if lowered.contains("<asx") { return .asx }
        if lowered.contains("http://xspf.org/ns") { return .xspf }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    private func parseM3u(baseURL: URL, content: String) -> [URL] {
        var res: [URL] = []
        for l in content.split(separator: "\n") {
            let line = l.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            if line.hasPrefix("#") { continue }

            if let url = URL(string: line, relativeTo: baseURL)?.absoluteURL {
                res.append(url)
            }
        }

        return !res.isEmpty ? res : [baseURL]
    }

    /* ****************************************
     *
     * ****************************************/
    private func parsePls(baseURL: URL, content: String) -> [URL] {
        var res: [URL] = []
        for l in content.split(separator: "\n") {
            let line = l.trimmingCharacters(in: .whitespacesAndNewlines)
            if !line.hasPrefix("File") { continue }

            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }

            if let url = URL(string: String(parts[1]), relativeTo: baseURL)?.absoluteURL {
                res.append(url)
            }
        }

        return !res.isEmpty ? res : [baseURL]
    }

    /* ****************************************
     *
     * ****************************************/
    private func parseAsx(baseURL: URL, content: String) -> [URL] {
        guard let data = content.data(using: .utf8),
              let doc = try? XMLDocument(data: data, options: .documentTidyXML) else {
            return [baseURL]
        }

        var urls: [URL] = []

        do {
            let nodes = try doc.nodes(forXPath: "//ref")
            for node in nodes {
                if let element = node as? XMLElement,
                   let href = element.attribute(forName: "href")?.stringValue,
                   let url = URL(string: href, relativeTo: baseURL)?.absoluteURL {
                    urls.append(url)
                }
            }
        } catch {
            return [baseURL]
        }

        return !urls.isEmpty ? urls : [baseURL]
    }

    /* ****************************************
     *
     * ****************************************/
    private func parseXspf(baseURL: URL, content: String) -> [URL] {
        guard let data = content.data(using: .utf8),
              let doc = try? XMLDocument(data: data, options: .documentTidyXML) else {
            return [baseURL]
        }

        var urls: [URL] = []

        do {
            let nodes = try doc.nodes(forXPath: "//track/location")
            for node in nodes {
                if let element = node as? XMLElement,
                   let text = element.stringValue,
                   let url = URL(string: text, relativeTo: baseURL)?.absoluteURL {
                    urls.append(url)
                }
            }
        } catch {
            // Ошибка XPath — fallback
            return [baseURL]
        }

        return !urls.isEmpty ? urls : [baseURL]
    }
}
