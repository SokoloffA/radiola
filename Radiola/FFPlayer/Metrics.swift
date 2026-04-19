//
//  Metrics.swift
//  Radiola
//
//  Created by Alex Sokolov on 19.04.2026.
//

import Foundation

#if DEBUG

    final class SpeedMetric {
        var name = ""
        private var sentBytes = 0
        private var lastLog = Date()

        init(name: String = "") {
            self.name = name
        }

        func record(_ bytes: Int) {
            sentBytes += bytes

            let now = Date()
            let elapsed = now.timeIntervalSince(lastLog)
            guard elapsed >= 1.0 else { return }

            let kbps = Double(sentBytes * 8) / elapsed / 1000.0
            debug("\(name) rate: \(Int(kbps)) kbit/s")
            sentBytes = 0
            lastLog = now
        }
    }

    final class CounterMetric {
        var name = ""
        private var value = 0
        private var lastLog = Date()

        init(name: String = "") {
            self.name = name
        }

        func record(_ val: Int) {
            value += val

            let now = Date()
            let elapsed = now.timeIntervalSince(lastLog)
            guard elapsed >= 1.0 else { return }

            debug("\(name): \(Int(value))")
            value = 0
            lastLog = now
        }
    }

    final class GaugeMetric {
        var name = ""
        private var min = Int.max
        private var max = Int.min
        private var sum = 0
        private var count = 0
        private var lastLog = Date()

        init(name: String = "") {
            self.name = name
        }

        func record(_ val: Int) {
            if val < min { min = val }
            if val > max { max = val }
            sum += val
            count += 1

            let now = Date()
            let elapsed = now.timeIntervalSince(lastLog)
            guard elapsed >= 1.0 else { return }

            let avg = count > 0 ? sum / count : 0
            debug("\(name): min=\(min) avg=\(avg) max=\(max)")

            min = Int.max
            max = Int.min
            sum = 0
            count = 0
            lastLog = now
        }
    }

#else
    final class NoopMetric {
        @inline(__always) init(name: String = "") {}
        @inline(__always) func record(_ bytes: Int) {}
    }

    typealias SpeedMetric = NoopMetric
    typealias CounterMetric = NoopMetric
    typealias GaugeMetric = NoopMetric
#endif
