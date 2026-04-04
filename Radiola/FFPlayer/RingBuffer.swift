//
//  RingBuffer.swift
//  Radiola
//
//  Created by Alex Sokolov on 15.03.2026.
//

import Foundation

// MARK: - RingBuffer

class RingBuffer {
    let buffersCount: Int
    let bufferSize: Int

    class Buffer {
        var audioData: [UInt8]
        var audioDataByteSize: Int = 0

        init(bufferSize: Int) {
            audioData = [UInt8](repeating: 0, count: bufferSize)
        }
    }

    var buffers: [Buffer]

    private var _readIndex: Int64 = 0
    private var _writeIndex: Int64 = 0
    private var mutex = pthread_mutex_t()

    /* ****************************************
     *
     * ****************************************/
    init(buffersCount: Int, bufferSize: Int) {
        self.bufferSize = bufferSize
        self.buffersCount = buffersCount
        buffers = (0 ..< buffersCount).map { _ in Buffer(bufferSize: bufferSize) }
        pthread_mutex_init(&mutex, nil)
    }

    /* ****************************************
     *
     * ****************************************/
    deinit {
        pthread_mutex_destroy(&mutex)
    }

    /* ****************************************
     *
     * ****************************************/
    func reset() {
        pthread_mutex_lock(&mutex)
        defer { pthread_mutex_unlock(&mutex) }

        _readIndex = 0
        _writeIndex = 0
    }

    /* ****************************************
     *
     * ****************************************/
    func readIndex() -> Int? {
        pthread_mutex_lock(&mutex)
        defer { pthread_mutex_unlock(&mutex) }

        if _readIndex < _writeIndex {
            return Int(_readIndex % Int64(buffers.count))
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func writeIndex() -> Int? {
        pthread_mutex_lock(&mutex)
        defer { pthread_mutex_unlock(&mutex) }

        if _writeIndex - _readIndex < buffers.count {
            return Int(_writeIndex % Int64(buffers.count))
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    func readyNum() -> Int {
        pthread_mutex_lock(&mutex)
        defer { pthread_mutex_unlock(&mutex) }
        return Int(_writeIndex - _readIndex)
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    func incReadIndex() -> Int {
        pthread_mutex_lock(&mutex)
        defer { pthread_mutex_unlock(&mutex) }
        _readIndex += 1
        return Int(_readIndex % Int64(buffers.count))
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    func incWriteIndex() -> Int {
        pthread_mutex_lock(&mutex)
        defer { pthread_mutex_unlock(&mutex) }
        _writeIndex += 1
        return Int(_writeIndex % Int64(buffers.count))
    }

    /* ****************************************
     *
     * ****************************************/
    func debug(_ prefix: String) {
        pthread_mutex_lock(&mutex)
        defer { pthread_mutex_unlock(&mutex) }
        let r = Int(_readIndex % Int64(buffers.count))
        let w = Int(_writeIndex % Int64(buffers.count))
        print("\(Date()) [\(pthread_mach_thread_np(pthread_self()))]  \(prefix): read: \(_readIndex) write:\(_writeIndex) ready: \(_writeIndex - _readIndex) [r: \(r) w: \(w)]")
    }
}
