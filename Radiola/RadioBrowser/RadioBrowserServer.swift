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
            url.path = path
            url.queryItems = queryItems

            guard let url = url.url else {
                throw RadioBrowser.Error.invalidURL
            }

            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.iso8601

            return try decoder.decode(type, from: data)
        }
    }
}

extension RadioBrowser {
    // ******************************************************************
    /// Do a DNS-lookup of 'all.api.radio-browser.info'. This gives you a list of all available servers.
    public static func getAllServers() throws -> [Server] {
        let dnsName = "all.api.radio-browser.info"

        var res: [Server] = []

        let host = CFHostCreateWithName(nil, dnsName as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        guard let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray? else { return [] }

        for case let addr as NSData in addresses {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(addr.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(addr.length), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                if let url = URL(string: "http://" + String(cString: hostname)) {
                    res.append(Server(url: url))
                }
            }
        }

        if res.isEmpty {
            throw RadioBrowser.Error.dnsError
        }

        return res
    }

    // ******************************************************************
    /// Do a DNS-lookup of 'all.api.radio-browser.info'. This gives you a rundom server from all available servers.
    public static func getRundomServer() throws -> Server {
        return try getAllServers().shuffled().first!
    }

    // ******************************************************************
    /// Do a DNS-lookup of 'all.api.radio-browser.info'. This gives you a fastest server from all available servers.
    public static func getFastestServer() async throws -> Server {
        func ping(_ servers: [Server]) -> AsyncStream<Server?> {
            var index = 0

            return AsyncStream {
                guard index < servers.count else {
                    return nil
                }

                let server = servers[index]
                index += 1

                var request = URLRequest(url: server.url)
                request.httpMethod = "HEAD"

                if (try? await URLSession.shared.data(for: request)) != nil {
                    return server
                }

                return nil
            }
        }

        for try await server in ping(try getAllServers()) {
            if server != nil {
                return server!
            }
        }

        throw RadioBrowser.Error.dnsError
    }
}
