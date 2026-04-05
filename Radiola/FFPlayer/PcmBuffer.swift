//
//  PcmBuffer.swift
//  Radiola
//
//  Created by Alex Sokolov on 05.04.2026.
//

import Foundation

// MARK: - PcmBuffer

class PcmBuffer {
    private let capacity: Int
    private let buffer: UnsafeMutableRawPointer
    private var writePos: Int = 0
    private var readPos: Int = 0
    private var count: Int = 0

    private var readBuffer: UnsafeMutableRawPointer?
    private var readBufferCapacity: Int = 0

    /* ****************************************
     *
     * ****************************************/
    init(capacity: Int) {
        self.capacity = capacity
        buffer = UnsafeMutableRawPointer.allocate(byteCount: capacity, alignment: 16)
    }

    /* ****************************************
     *
     * ****************************************/
    deinit {
        buffer.deallocate()
        readBuffer?.deallocate()
    }

    /* ****************************************
     *
     * ****************************************/
    var available: Int { count }

    /* ****************************************
     *
     * ****************************************/
    func write(_ src: UnsafeRawPointer, _ bytes: Int) {
        let firstChunk = min(bytes, capacity - writePos)
        buffer.advanced(by: writePos).copyMemory(from: src, byteCount: firstChunk)

        if bytes > firstChunk {
            buffer.copyMemory(from: src.advanced(by: firstChunk), byteCount: bytes - firstChunk)
        }

        writePos = (writePos + bytes) % capacity
        count += bytes
    }

    /* ****************************************
     * Returns pointer to bytes for reading.
     * If data is contiguous — returns direct pointer into buffer (no copy).
     * If wraparound — copies into internal readBuffer and returns that.
     * Caller must call consume() after processing.
     * ****************************************/
    func readPointer(bytes: Int) -> UnsafeRawPointer? {
        guard count >= bytes else { return nil }

        // The data is continuous — we return a direct pointer without copying
        if readPos + bytes <= capacity {
            return UnsafeRawPointer(buffer.advanced(by: readPos))
        }

        // Wraparound — copy to the internal buffer
        if bytes > readBufferCapacity {
            readBuffer?.deallocate()
            readBuffer = UnsafeMutableRawPointer.allocate(byteCount: bytes, alignment: 16)
            readBufferCapacity = bytes
        }

        let dest = readBuffer!
        let firstChunk = capacity - readPos
        dest.copyMemory(from: buffer.advanced(by: readPos), byteCount: firstChunk)
        dest.advanced(by: firstChunk).copyMemory(from: buffer, byteCount: bytes - firstChunk)

        return UnsafeRawPointer(dest)
    }

    /* ****************************************
     *
     * ****************************************/
    func consume(_ bytes: Int) {
        readPos = (readPos + bytes) % capacity
        count -= bytes
    }

    /* ****************************************
     *
     * ****************************************/
    func reset() {
        writePos = 0
        readPos = 0
        count = 0
    }
}
