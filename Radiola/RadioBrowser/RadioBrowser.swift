//
//  RadioBrowser.swift
//  Radiola
//
//  Created by Alex Sokolov on 28.08.2023.
//

import Foundation

class RadioBrowser {
    internal static func getServer() -> String? {
        let dnsName = "all.api.radio-browser.info"

        var res: [String] = []

        let host = CFHostCreateWithName(nil, dnsName as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        guard let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray? else { return nil }

        for case let addr as NSData in addresses {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(addr.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(addr.length), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                res.append(String(cString: hostname))
            }
        }

        if res.isEmpty {
            return nil
        }

        let n = Int.random(in: 0 ..< res.count)
        return res[n]
    }
}

public enum RadioBrowserError: Error {
    case dnsError
    case invalidURL
    case missingData
}
