//
//  Stations.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 01.12.2023.
//

import Cocoa

// MARK: - StationItem

let StationItemPasteboardType = NSPasteboard.PasteboardType(rawValue: "Station.row")

protocol StationItem: AnyObject {
    var id: UUID { get }
    var title: String { get set }
}

// MARK: - Station

protocol Station: StationItem {
    var id: UUID { get }
    var title: String { get set }
    var url: String { get set }
    var isFavorite: Bool { get set }
    var homepageUrl: String? { get set }
    var iconUrl: String? { get set }
}

extension Station {
    /* ****************************************
     *
     * ****************************************/
    func fill(from: Station) {
        title = from.title
        url = from.url
        isFavorite = from.isFavorite
        homepageUrl = from.homepageUrl
        iconUrl = from.iconUrl
    }
}

// MARK: - StationGroup

protocol StationGroup: StationItem {
    var id: UUID { get }
    var title: String { get set }
    var items: [StationItem] { get set }
}

extension StationGroup {
    /* ****************************************
     *
     * ****************************************/
    func fill(from: StationGroup) {
        title = from.title
    }

    /* ****************************************
     *
     * ****************************************/
    func append(_ item: StationItem) {
        items.append(item)
    }

    /* ****************************************
     *
     * ****************************************/
    func insert(_ item: StationItem, afterId: UUID) {
        let index = items.firstIndex { $0.id == afterId }

        if let index = index {
            if index < items.count - 1 {
                items.insert(item, at: index + 1)
            } else {
                append(item)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func index(_ itemId: UUID) -> Int? {
        return items.firstIndex { $0.id == itemId }
    }
}

// MARK: - StationIconLoader

final class StationIconLoader {
    static let shared = StationIconLoader()

    private let cache = NSCache<NSString, NSImage>()
    private let queue = DispatchQueue(label: "StationIconLoader")
    private var inFlight: [NSString: [(NSImage?) -> Void]] = [:]
    private var metadataInFlight: [NSString: [(NSImage?) -> Void]] = [:]
    private var metadataFailed = Set<String>()

    private let placeholder: NSImage? = NSImage(
        systemSymbolName: NSImage.Name("antenna.radiowaves.left.and.right"),
        accessibilityDescription: ""
    )?.tint(color: .secondaryLabelColor)

    func placeholderImage() -> NSImage? {
        return placeholder
    }

    func loadIcon(for station: Station, completion: @escaping (NSImage?) -> Void) {
        if let url = iconURL(for: station) {
            loadIcon(from: url, completion: completion)
            return
        }

        let metaKey = NSString(string: "meta:\(station.id.uuidString)")
        queue.async {
            if self.metadataFailed.contains(metaKey as String) {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            if self.metadataInFlight[metaKey] != nil {
                self.metadataInFlight[metaKey]?.append(completion)
                return
            }

            self.metadataInFlight[metaKey] = [completion]

            Task {
                let image = await self.resolveAndLoadIcon(for: station)

                self.queue.async {
                    let completions = self.metadataInFlight[metaKey] ?? []
                    self.metadataInFlight[metaKey] = nil
                    if image == nil {
                        self.metadataFailed.insert(metaKey as String)
                    }
                    DispatchQueue.main.async {
                        for handler in completions {
                            handler(image)
                        }
                    }
                }
            }
        }
    }

    private func loadIcon(from url: URL, completion: @escaping (NSImage?) -> Void) {
        let key = NSString(string: url.absoluteString)
        if let cached = cache.object(forKey: key) {
            DispatchQueue.main.async {
                completion(cached)
            }
            return
        }

        queue.async {
            if self.inFlight[key] != nil {
                self.inFlight[key]?.append(completion)
                return
            }

            self.inFlight[key] = [completion]

            let task = URLSession.shared.dataTask(with: url) { data, _, _ in
                var image: NSImage?
                if let data = data {
                    image = NSImage(data: data)
                }

                if let image = image {
                    self.cache.setObject(image, forKey: key)
                }

                self.queue.async {
                    let completions = self.inFlight[key] ?? []
                    self.inFlight[key] = nil
                    DispatchQueue.main.async {
                        for handler in completions {
                            handler(image)
                        }
                    }
                }
            }

            task.resume()
        }
    }

    private func resolveAndLoadIcon(for station: Station) async -> NSImage? {
        if let url = iconURL(for: station) {
            return await downloadAndCache(url: url)
        }

        guard let metadata = await resolveMetadata(for: station) else {
            return nil
        }

        await MainActor.run {
            if let homepage = metadata.homepage {
                station.homepageUrl = homepage
            }
            if let icon = metadata.icon {
                station.iconUrl = icon
            }
            AppState.shared.saveStationMetadata(station)
        }

        guard let url = iconURL(for: station) else {
            return nil
        }

        return await downloadAndCache(url: url)
    }

    private func resolveMetadata(for station: Station) async -> (homepage: String?, icon: String?)? {
        let title = station.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty {
            return nil
        }

        guard let server = try? await RadioBrowser.getFastestServer() else {
            return nil
        }

        let exact = try? await server.listStations(by: .byNameExact, searchTerm: title, order: .name, limit: 50)
        if let match = pickBestMatch(exact ?? [], station: station) {
            return normalizeMetadata(match)
        }

        let fuzzy = try? await server.listStations(by: .byName, searchTerm: title, order: .name, limit: 50)
        if let match = pickBestMatch(fuzzy ?? [], station: station) {
            return normalizeMetadata(match)
        }

        return nil
    }

    private func pickBestMatch(_ stations: [RadioBrowser.Station], station: Station) -> RadioBrowser.Station? {
        let url = station.url
        if let match = stations.first(where: { $0.url == url || $0.url_resolved == url }) {
            return match
        }
        return stations.first
    }

    private func normalizeMetadata(_ station: RadioBrowser.Station) -> (homepage: String?, icon: String?) {
        let homepage = station.homepage.isEmpty ? nil : station.homepage
        let icon = station.favicon.isEmpty ? nil : station.favicon
        return (homepage: homepage, icon: icon)
    }

    private func downloadAndCache(url: URL) async -> NSImage? {
        let key = NSString(string: url.absoluteString)
        if let cached = cache.object(forKey: key) {
            return cached
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = NSImage(data: data) {
                cache.setObject(image, forKey: key)
                return image
            }
        } catch {
        }

        return nil
    }

    private func iconURL(for station: Station) -> URL? {
        if let iconUrl = normalizedURLString(station.iconUrl) {
            return URL(string: iconUrl)
        }

        if let homepage = normalizedURLString(station.homepageUrl),
           let homepageUrl = URL(string: homepage),
           let host = homepageUrl.host {
            let scheme = homepageUrl.scheme ?? "https"
            return URL(string: "\(scheme)://\(host)/favicon.ico")
        }

        return nil
    }

    private func normalizedURLString(_ raw: String?) -> String? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return nil
        }

        if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
            return raw
        }

        return "https://\(raw)"
    }
}
