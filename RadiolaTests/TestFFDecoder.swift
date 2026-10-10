//
//  TestFFDecoder.swift
//  RadiolaTests
//

import FFAudio
@testable import Radiola
import XCTest

extension RadiolaTests {
    /* ****************************************
     * The stream contains AAC frames the decoder rejects with
     * AVERROR_INVALIDDATA, at the start (as when joining a live stream
     * mid-frame) and in the middle. The decoder must skip them and
     * decode the whole stream up to EOF.
     * ****************************************/
    func testDecodeInvalidPackets() throws {
        let url = dataDir(testName: #function).appendingPathComponent("source.aac")
        let ringBuffer = RingBuffer(buffersCount: 1, bufferSize: 8192)
        let decoder = FFDecoder(ringBuffer: ringBuffer, shouldInterrupt: AtomicBool())

        try decoder.load(url: url)
        defer { decoder.stop() }

        var decodedBytes = 0
        do {
            while true {
                try decoder.decodeBuffer(outBuffer: ringBuffer.buffers[0])
                decodedBytes += ringBuffer.buffers[0].audioDataByteSize
            }
        } catch let error as NSError {
            XCTAssertEqual(error.code, Int(averror_eof), error.debugDescription)
        }

        // The source is 3 seconds long, 7 of its 131 frames are invalid.
        let format = decoder.format
        let bytesPerSecond = Int(format.sampleRate) * Int(format.channelsNum) * format.bytesPerSample
        XCTAssertGreaterThan(Double(decodedBytes) / Double(bytesPerSecond), 2.5)
    }
}
