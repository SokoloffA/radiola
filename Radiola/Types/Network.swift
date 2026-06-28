//
//  NetWork.swift
//  Radiola
//
//  Created by Alex Sokolov on 28.06.2026.
//

import Foundation

/* ****************************************
 *
 * ****************************************/
@available(macOS 12.0, *)
func fetchHTTPHeaders(request: URLRequest, encoding: String.Encoding = .utf8) async throws -> [String: String] {
    let (bytes, response) = try await URLSession.shared.bytes(for: request)

    bytes.task.cancel()

    guard let httpResponse = response as? HTTPURLResponse else {
        throw RadiolaError("Not an HTTP response")
    }

    var res = [String: String]()
    for (k, v) in httpResponse.allHeaderFields {
        guard
            let key = (k as? String)?.lowercased(),
            let rawVal = v as? String
        else {
            continue
        }

        if let data = rawVal.data(using: .isoLatin1), let val = String(data: data, encoding: encoding) {
            res[key] = val
        } else {
            res[key] = rawVal
        }
    }

    return res
}
