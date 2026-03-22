//
//  MacAudio.swift
//  Radiola
//
//  Created by Alex Sokolov on 15.03.2026.
//

import AudioToolbox
import FFAudio
import Foundation

// MARK: - MacAudio

class MacAudio {
    private var audioQueue: AudioQueueRef?
    private var audioQueueBuffers: [AudioQueueBufferRef?]
    private var format: AudioStreamBasicDescription?
    private let ringBuffer: RingBuffer
    let numBuffers: Int

    /* ****************************************
     *
     * ****************************************/
    init(ringBuffer: RingBuffer, numBuffers: Int) {
        self.ringBuffer = ringBuffer
        self.numBuffers = numBuffers
        audioQueueBuffers = [AudioQueueBufferRef?](repeating: nil, count: ringBuffer.buffersCount)
    }

    /* ****************************************
     *
     * ****************************************/
    func start(format ffFormat: FFDecoder.Format, deviceUID: String?) throws {
        var format = makeASBD(format: ffFormat)
        self.format = format

        let err = AudioQueueNewOutput(
            &format,
            fillAudioQueueBuffer,
            Unmanaged.passUnretained(ringBuffer).toOpaque(),
            nil,
            nil,
            0,
            &audioQueue)

        if err < 0 {
            throw NSError(code: .alocError_AudioQueue, message: internalErrorDescription, debug: "Error calling AudioQueueNewOutput")
        }

        guard let audioQueue = audioQueue else { return }

        if let deviceUID = deviceUID {
            let cfUID = deviceUID as CFString
            try withUnsafePointer(to: cfUID) { ptr in
                let rawPtr = UnsafeRawPointer(ptr)
                let err = AudioQueueSetProperty(audioQueue, kAudioQueueProperty_CurrentDevice, rawPtr, UInt32(MemoryLayout<CFString?>.size))

                if err != noErr {
                    throw NSError(code: .setDeviceError, error: err, message: internalErrorDescription, debug: "Error setting audio device")
                }
            }
        }

        for i in 0 ..< numBuffers {
            var buffer: AudioQueueBufferRef?
            let err = AudioQueueAllocateBuffer(audioQueue, UInt32(ringBuffer.bufferSize), &buffer)

            if err != noErr || buffer == nil {
                throw NSError(code: .alocError_AudioQueueBuffer, message: internalErrorDescription, debug: "Error calling AudioQueueAllocateBuffer")
            }

            audioQueueBuffers[i] = buffer
            fillAudioQueueBuffer(userData: Unmanaged.passUnretained(ringBuffer).toOpaque(), outAQ: audioQueue, outBuffer: buffer!)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func startQueue() throws {
        guard let audioQueue = audioQueue else { return }
        let err = AudioQueueStart(audioQueue, nil)
        if err != noErr {
            throw NSError(code: .audioQueueStartError, error: err, message: internalErrorDescription, debug: "Error calling AudioQueueStart")
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func stop() {
        if let audioQueue = audioQueue {
            AudioQueueStop(audioQueue, true)
            AudioQueueDispose(audioQueue, true)
            self.audioQueue = nil
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func makeASBD(format: FFDecoder.Format) -> AudioStreamBasicDescription {
        var res = AudioStreamBasicDescription()
        res.mSampleRate = Double(format.sampleRate)
        res.mFormatID = kAudioFormatLinearPCM

        // sample type detection
        switch format.sampleFormat {
            case AV_SAMPLE_FMT_FLT, AV_SAMPLE_FMT_FLTP:
                res.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked
                res.mBitsPerChannel = 32

            case AV_SAMPLE_FMT_S16, AV_SAMPLE_FMT_S16P:
                res.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
                res.mBitsPerChannel = 16

            case AV_SAMPLE_FMT_S32, AV_SAMPLE_FMT_S32P:
                res.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
                res.mBitsPerChannel = 32

            case AV_SAMPLE_FMT_U8, AV_SAMPLE_FMT_U8P:
                res.mFormatFlags = kAudioFormatFlagIsPacked
                res.mBitsPerChannel = 8

            default:
                // std::cerr << "Unsupported sample format: " << av_get_sample_fmt_name(outFmt) << std::endl;
                res.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
                res.mBitsPerChannel = 16
        }

        res.mChannelsPerFrame = UInt32(format.channelsNum)
        res.mFramesPerPacket = 1
        res.mBytesPerFrame = (res.mBitsPerChannel / 8) * res.mChannelsPerFrame
        res.mBytesPerPacket = res.mBytesPerFrame
        res.mReserved = 0

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    func setVolume(_ volume: Float) throws {
        guard let audioQueue = audioQueue else { return }

        let err = AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, volume)
        if err != noErr {
            throw NSError(code: .setVolumeError, error: err, message: internalErrorDescription, debug: "Error calling AudioQueueSetParameter")
        }
    }
}

// MARK: - AudioQueue callback

fileprivate func fillAudioQueueBuffer(userData: UnsafeMutableRawPointer?, outAQ: AudioQueueRef, outBuffer: AudioQueueBufferRef) {
    guard let userData = userData else { return }
    let ringBuffer = Unmanaged<RingBuffer>.fromOpaque(userData).takeUnretainedValue()

    guard let index = ringBuffer.readIndex() else {
        let silent = Array(repeating: UInt8(0), count: Int(ringBuffer.bufferSize))
        let dest = outBuffer.pointee.mAudioData

        outBuffer.pointee.mAudioDataByteSize = UInt32(silent.count)
        memcpy(dest, silent, silent.count)
        AudioQueueEnqueueBuffer(outAQ, outBuffer, 0, nil)
        return
    }

    let src = ringBuffer.buffers[index]
    let dest = outBuffer.pointee.mAudioData

    outBuffer.pointee.mAudioDataByteSize = UInt32(src.audioDataByteSize)
    memcpy(dest, src.audioData, src.audioDataByteSize)
    AudioQueueEnqueueBuffer(outAQ, outBuffer, 0, nil)
    ringBuffer.incReadIndex()
}
