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

    private let placeholder: NSImage? = NSImage(
        systemSymbolName: NSImage.Name("antenna.radiowaves.left.and.right"),
        accessibilityDescription: ""
    )?.tint(color: .secondaryLabelColor)

    func placeholderImage() -> NSImage? {
        return placeholder
    }

    func loadIcon(for station: Station, completion: @escaping (NSImage?) -> Void) {
        guard let url = iconURL(for: station) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

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
