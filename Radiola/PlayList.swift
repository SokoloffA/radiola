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
    struct Link {
        let url: URL
        let title: String?
    }

    private(set) var links: [Link] = []
    var urls: [URL] { links.compactMap { $0.url } }

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
                self.links = [Link(url: url, title: nil)]
                return
            }

            switch format {
                case .hls: break
                case .m3u: self.parseM3u(baseURL: url, content: content)
                case .pls: self.parsePls(baseURL: url, content: content)
                case .asx: self.parseAsx(baseURL: url, content: content)
                case .xspf: self.parseXspf(baseURL: url, content: content)
            }

            if self.links.isEmpty {
                self.links = [Link(url: url, title: nil)]
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
    private func parseM3u(baseURL: URL, content: String) {
        var title: String?

        for l in content.split(separator: "\n") {
            let line = l.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            if line.hasPrefix("#") {
                if line.hasPrefix("#EXTINF:") {
                    title = extractM3uTitle(line)
                }
                continue
            }

            if let url = URL(string: line, relativeTo: baseURL)?.absoluteURL {
                links.append(PlayList.Link(url: url, title: title))
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func extractM3uTitle(_ line: String) -> String? {
        var inQuotes = false

        for i in line.indices {
            let c = line[i]

            if c == "\"" {
                inQuotes.toggle()
            } else if c == "," && !inQuotes {
                let n = line.index(after: i)
                return line[n...].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }

    /* ****************************************
     * https://en.wikipedia.org/wiki/PLS_(file_format)
     * ****************************************/
    private func parsePls(baseURL: URL, content: String) {
        var urls: [Int: URL] = [:]
        var titles: [Int: String] = [:]

        for l in content.components(separatedBy: .newlines) {
            let line = l.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let val = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)

            if key.hasPrefix("File") {
                guard let num = Int(key.dropFirst(4)) else { continue }
                if let url = URL(string: String(val), relativeTo: baseURL)?.absoluteURL {
                    urls[num] = url
                }
            } else if key.hasPrefix("Title") {
                guard let num = Int(key.dropFirst(5)) else { continue }
                titles[num] = val
            }
        }

        for key in urls.keys.sorted() {
            guard let url = urls[key] else { continue }
            links.append(PlayList.Link(url: url, title: titles[key]))
        }
    }

    /* ****************************************
     * https://handwiki.org/wiki/Advanced_Stream_Redirector
     * ****************************************/
    private func parseAsx(baseURL: URL, content: String) {
        func firstElement(of entry: XMLElement, forName: String) -> XMLElement? {
            var res = entry.elements(forName: forName)
            if res.isEmpty { res = entry.elements(forName: forName.uppercased()) }
            return res.first
        }

        func attributeValue(of element: XMLElement, forName: String) -> String? {
            if let val = element.attribute(forName: forName)?.stringValue { return val }
            return element.attribute(forName: forName.uppercased())?.stringValue
        }

        guard
            let data = content.data(using: .utf8),
            let doc = try? XMLDocument(data: data, options: .documentTidyXML)
        else {
            return
        }

        do {
            let nodes = try doc.nodes(forXPath: "//*[local-name()='entry' or local-name()='ENTRY']")

            for node in nodes {
                guard
                    let entry = node as? XMLElement,
                    let ref = firstElement(of: entry, forName: "ref"),
                    let href = attributeValue(of: ref, forName: "href")?.trimmingCharacters(in: .whitespacesAndNewlines),
                    let url = URL(string: href, relativeTo: baseURL)?.absoluteURL
                else {
                    continue
                }
                let title = firstElement(of: entry, forName: "title")?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)

                links.append(PlayList.Link(url: url, title: title))
            }
        } catch {
        }
    }

    /* ****************************************
     * https://xspf.org/quickstart
     * ****************************************/
    private func parseXspf(baseURL: URL, content: String) {
        guard
            let data = content.data(using: .utf8),
            let doc = try? XMLDocument(data: data, options: .documentTidyXML)
        else {
            return
        }

        do {
            let nodes = try doc.nodes(forXPath: "//*[local-name()='track']")

            for node in nodes {
                guard
                    let entry = node as? XMLElement,
                    let location = entry.elements(forName: "location").first,
                    let href = location.stringValue,
                    let url = URL(string: href, relativeTo: baseURL)?.absoluteURL
                else {
                    continue
                }
                let title = entry.elements(forName: "title").first?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)

                links.append(PlayList.Link(url: url, title: title))
            }
        } catch {
        }
    }
}
