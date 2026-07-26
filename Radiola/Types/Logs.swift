//
//  Logs.swift
//  Radiola
//
//  Created by Alex Sokolov on 26.07.2026.
//

import Foundation

/* ****************************************
 *
 * ****************************************/
fileprivate var logsData: [String] = []

/* ****************************************
 *
 * ****************************************/
func allLogs() -> [String] {
    return logsData
}

/* ****************************************
 *
 * ****************************************/
private let logDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    formatter.timeZone = .current
    return formatter
}()

/* ****************************************
 *
 * ****************************************/
fileprivate func logMsg(prefix: String, _ items: Any..., separator: String = " ", terminator: String = "\n") {
    let timestamp = logDateFormatter.string(from: Date())
    let threadId = pthread_mach_thread_np(pthread_self())
    let payload = items.map { "\($0)" }.joined(separator: separator)

    let s = "\(prefix): \(timestamp) [\(threadId)] \(payload)"
    logsData.append(s)
    print(s)
}

/* ****************************************
 *
 * ****************************************/
func debug(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    logMsg(prefix: "Debug", items, separator: separator, terminator: terminator)
}

/* ****************************************
 *
 * ****************************************/
func warning(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    logMsg(prefix: "Warning", items, separator: separator, terminator: terminator)
}
