//
//  RadioBrowserServer.swift
//  Radiola
//
//  Created by Alex Sokolov on 13.10.2023.
//

import Foundation

extension RadioBrowser {
    // ******************************************************************
    /// The class represents one of the api.radio-browser.info servers
    struct Server {
        let url: URL

        // ******************************************************************
        internal func fetch<T>(_ type: T.Type, path: String, queryItems: [URLQueryItem]) async throws -> T where T: Decodable {
            var url = URLComponents()
            url.scheme = self.url.scheme
            url.host = self.url.host
            url.port = self.url.port
            url.path = path
            url.queryItems = queryItems

            guard let url = url.url else {
                throw RadioBrowser.Error("Invalid URL \(url)")
            }

            let config = URLSessionConfiguration.default

            if let proxyDict = httpProxyDictionaryFromEnv() {
                config.connectionProxyDictionary = proxyDict
            }

            let session = URLSession(configuration: config)
            let (data, _) = try await session.data(from: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.iso8601

            debug("Fetch \(url.absoluteString)")
            do {
                return try decoder.decode(type, from: data)
            } catch let error {
                warning(error)
                throw error
            }
        }

        /* ****************************************
         *
         * ****************************************/
        internal func httpProxyDictionaryFromEnv() -> [String: Any]? {
            let env = ProcessInfo.processInfo.environment

            guard
                let raw = env["http_proxy"] ?? env["HTTP_PROXY"],
                !raw.isEmpty
            else {
                return nil
            }

            let urlString: String
            if raw.contains("://") {
                urlString = raw
            } else {
                urlString = "http://\(raw)"
            }

            guard
                let url = URL(string: urlString),
                let host = url.host,
                let port = url.port
            else {
                return nil
            }

            return [
                kCFNetworkProxiesHTTPEnable as String: true,
                kCFNetworkProxiesHTTPProxy as String: host,
                kCFNetworkProxiesHTTPPort as String: port,

                kCFNetworkProxiesHTTPSEnable as String: true,
                kCFNetworkProxiesHTTPSProxy as String: host,
                kCFNetworkProxiesHTTPSPort as String: port,
            ]
        }
    }
}

extension RadioBrowser {
    // ******************************************************************
    /// Do a DNS-lookup of 'all.api.radio-browser.info'. This gives you a list of all available servers.
    public static func getAllServers() throws -> [Server] {
        let dnsName = "all.api.radio-browser.info"
        var urls = Set<URL>()

        var results: UnsafeMutablePointer<addrinfo>?
        defer {
            if let results = results {
                freeaddrinfo(results)
            }
        }

        if getaddrinfo(dnsName, nil, nil, &results) != 0 {
            throw RadioBrowser.Error("Unable to resolve DNS name \(dnsName)", failureReason: "the getaddrinfo call failed")
        }

        for addrinfo in sequence(first: results, next: { $0?.pointee.ai_next }) {
            guard let pointee = addrinfo?.pointee else { break }

            let hostname = UnsafeMutablePointer<Int8>.allocate(capacity: Int(NI_MAXHOST))
            defer {
                hostname.deallocate()
            }
            let error = getnameinfo(pointee.ai_addr, pointee.ai_addrlen, hostname, socklen_t(NI_MAXHOST), nil, 0, 0)
            if error != 0 {
                continue
            }

            if let url = URL(string: "http://" + String(cString: hostname)) {
                urls.insert(url)
            }
        }

        return Array(urls).map { Server(url: $0) }
    }

    // ******************************************************************
    /// Do a DNS-lookup of 'all.api.radio-browser.info'. This gives you a rundom server from all available servers.
    public static func getRundomServer() throws -> Server {
        return try getAllServers().shuffled().first!
    }

    // ******************************************************************
    //
    private static func pingServer(server: Server) async -> (Server, Bool) {
        do {
            let stats = try await server.stats()
            return (server, stats.status == Status.statusOK)
        } catch {
            do {
                try Task.checkCancellation()
            } catch {
                return (server, false)
            }

            print("Failed to ping \(server.url): \(error)") // .localizedDescription)")
            return (server, false)
        }
    }

    // ******************************************************************
    /// Do a DNS-lookup of 'all.api.radio-browser.info'. This gives you a fastest server from all available servers.
    public static func getFastestServer() async throws -> Server {
        let servers = try getAllServers()

        do {
            return try await withThrowingTaskGroup(of: (Server, Bool).self) { taskGroup in
                for server in servers {
                    taskGroup.addTask {
                        await pingServer(server: server)
                    }
                }

                for try await (server, isAvailable) in taskGroup {
                    if isAvailable {
                        taskGroup.cancelAll()
                        return server
                    }
                }

                throw RadioBrowser.Error("Unable to find an available server") // Если все серверы недоступны
            }
        }
    }
}
