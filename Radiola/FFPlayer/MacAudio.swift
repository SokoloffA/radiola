//
//  MacAudio.swift
//  Radiola
//
//  Created by Alex Sokolov on 15.03.2026.
//

import AVFoundation
import FFAudio
import Foundation

// MARK: - MacAudio

class MacAudio {
    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private let ringBuffer: RingBuffer
    let numBuffers: Int

    private var ffFormat: FFDecoder.Format?
    private var avFormat: AVAudioFormat?

    private var pcmBuffer: [UInt8] = []
    private var pcmBufferReadIndex: Int = 0

    private typealias ConvertFunc = ([UInt8], Int, UnsafeMutableAudioBufferListPointer, AVAudioFrameCount) -> Void
    private var fillConverter: ConvertFunc?

    private var configurationChangeObserver: NSObjectProtocol?

    private enum PCMScale {
        static let s16: Float32 = 1.0 / 32768.0
        static let s32: Float32 = 1.0 / 2_147_483_648.0
        static let u8: Float32 = 1.0 / 128.0
        static let u8bias: Float32 = -128.0
    }

    /* ****************************************
     *
     * ****************************************/
    init(ringBuffer: RingBuffer, numBuffers: Int) {
        self.ringBuffer = ringBuffer
        self.numBuffers = numBuffers
    }

    /* ****************************************
     *
     * ****************************************/
    func start(format ffFormat: FFDecoder.Format, audioDevice: AudioDevice?) throws {
        self.ffFormat = ffFormat
        self.avFormat = AVAudioFormat(standardFormatWithSampleRate: Double(ffFormat.sampleRate), channels: AVAudioFrameCount(ffFormat.channelsNum))
        guard let avFormat = avFormat else {
            throw NSError(code: .formatError, message: internalErrorDescription, debug: "Failed to create AVAudioFormat from FFDecoder.Format")
        }

        fillConverter = makeConverter(for: ffFormat)
        if fillConverter == nil {
            debug("FFFormat: \(ffFormat))")
            throw NSError(code: .formatError, message: internalErrorDescription, debug: "Failed to get converter function")
        }

        let engine = AVAudioEngine()
        self.engine = engine

        configurationChangeObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: nil
        ) { [weak self] _ in
            self?.handleEngineConfigurationChange()
        }

        try setVolume(0)

        let ringBufferRef = ringBuffer
        let sourceNode = AVAudioSourceNode(format: avFormat) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            self?.fillAudioBuffer(ringBufferRef, frameCount, audioBufferList)
            return noErr
        }
        self.sourceNode = sourceNode

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: avFormat)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: avFormat)

        if let audioDevice = audioDevice {
            try setOutputDevice(audioDevice: audioDevice, engine: engine)
        }

        try engine.start()
    }

    /* ****************************************
     *
     * ****************************************/
    private func fillAudioBuffer(_ ringBuffer: RingBuffer, _ frameCount: AVAudioFrameCount, _ audioBufferList: UnsafeMutablePointer<AudioBufferList>) {
        guard let ffFormat = ffFormat, let converter = fillConverter else { return }
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let channelCount = ablPointer.count
        let bytesNeeded = channelCount * Int(frameCount) * ffFormat.bytesPerSample

        while (pcmBuffer.count - pcmBufferReadIndex) < bytesNeeded {
            guard let index = ringBuffer.readIndex() else { break }
            let src = ringBuffer.buffers[index]
            pcmBuffer.append(contentsOf: src.audioData.prefix(src.audioDataByteSize))
            ringBuffer.incReadIndex()
        }

        converter(pcmBuffer, pcmBufferReadIndex, ablPointer, frameCount)
        pcmBufferReadIndex += min(bytesNeeded, pcmBuffer.count - pcmBufferReadIndex)

        if pcmBufferReadIndex > pcmBuffer.count / 2 {
            pcmBuffer.removeFirst(pcmBufferReadIndex)
            pcmBufferReadIndex = 0
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func stop() {
        if let observer = configurationChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            configurationChangeObserver = nil
        }

        engine?.stop()
        if let sourceNode = sourceNode, let engine = engine {
            engine.detach(sourceNode)
        }

        pcmBuffer.removeAll()
        pcmBufferReadIndex = 0
        sourceNode = nil
        engine = nil
        avFormat = nil
        ffFormat = nil
    }

    /* ****************************************
     *
     * ****************************************/
    func setVolume(_ volume: Float) {
        guard let engine = engine else { return }
        engine.mainMixerNode.outputVolume = volume
    }

    /* ****************************************
     *
     * ****************************************/
    func fadeInVolume(to targetVolume: Float, duration: TimeInterval = 0.1) {
        let steps = 20
        let stepDuration = duration / Double(steps)

        for i in 1 ... steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                guard let engine = self?.engine else { return }
                engine.mainMixerNode.outputVolume = targetVolume * Float(i) / Float(steps)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func setOutputDevice(audioDevice: AudioDevice, engine: AVAudioEngine) throws {
        var deviceID = audioDevice.deviceID

        let outputUnit = engine.outputNode.audioUnit
        let setErr = AudioUnitSetProperty(
            outputUnit!,
            kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Global,
            0,
            &deviceID,
            UInt32(MemoryLayout<AudioDeviceID>.size)
        )

        if setErr != noErr {
            throw NSError(code: .setDeviceError, error: setErr, message: internalErrorDescription, debug: "Error setting audio device on outputNode")
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func handleEngineConfigurationChange() {
        guard let engine = engine else { return }

        do {
            // engine stops automatically after a configuration change, just restart
            try engine.start()
        } catch {
            debug("Failed to restart engine after configuration change: \(error)")
        }
    }

    /* ****************************************
     * Copies planar (non-interleaved) data: each channel lies separately
     * ****************************************/
    private func makePlanarConverter<T: BinaryInteger>(_ type: T.Type, _ scale: Float32, _ bias: Float32 = 0.0) -> ConvertFunc {
        return { src, offset, ablPointer, frameCount in
            let frames = Int(frameCount)
            src.withUnsafeBytes { rawPtr in
                for (ch, buffer) in ablPointer.enumerated() {
                    guard let dest = buffer.mData else { continue }
                    let destPtr = dest.assumingMemoryBound(to: Float32.self)
                    let srcPtr = rawPtr.baseAddress!
                        .advanced(by: offset + ch * frames * MemoryLayout<T>.size)
                        .assumingMemoryBound(to: T.self)
                    for frame in 0 ..< frames {
                        destPtr[frame] = (Float32(srcPtr[frame]) + bias) * scale
                    }
                }
            }
        }
    }

    /* ****************************************
     * Converts interleaved float32 [L,R,L,R,...] to non-interleaved [[L,L,...],[R,R,...]]
     * ****************************************/
    private func makeInterleavedConverter<T: BinaryInteger>(_ type: T.Type, _ scale: Float32, _ bias: Float32 = 0.0) -> ConvertFunc {
        return { src, offset, ablPointer, frameCount in
            let frames = Int(frameCount)
            let channelCount = ablPointer.count
            src.withUnsafeBytes { rawPtr in
                let srcPtr = rawPtr.baseAddress!
                    .advanced(by: offset)
                    .assumingMemoryBound(to: T.self)
                for (ch, buffer) in ablPointer.enumerated() {
                    guard let dest = buffer.mData else { continue }
                    let destPtr = dest.assumingMemoryBound(to: Float32.self)
                    for frame in 0 ..< frames {
                        destPtr[frame] = (Float32(srcPtr[frame * channelCount + ch]) + bias) * scale
                    }
                }
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func makeConverter(for fmt: FFDecoder.Format) -> (([UInt8], Int, UnsafeMutableAudioBufferListPointer, AVAudioFrameCount) -> Void)? {
        switch fmt.sampleFormat {
            case AV_SAMPLE_FMT_FLTP: return convertFLTP
            case AV_SAMPLE_FMT_S16P: return makePlanarConverter(Int16.self, PCMScale.s16)
            case AV_SAMPLE_FMT_S32P: return makePlanarConverter(Int32.self, PCMScale.s32)
            case AV_SAMPLE_FMT_U8P: return makePlanarConverter(UInt8.self, PCMScale.u8, PCMScale.u8bias)
            case AV_SAMPLE_FMT_FLT: return convertFLT
            case AV_SAMPLE_FMT_S16: return makeInterleavedConverter(Int16.self, PCMScale.s16)
            case AV_SAMPLE_FMT_S32: return makeInterleavedConverter(Int32.self, PCMScale.s32)
            case AV_SAMPLE_FMT_U8: return makeInterleavedConverter(UInt8.self, PCMScale.u8, PCMScale.u8bias)
            default: return nil
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func convertFLTP(_ src: [UInt8], _ offset: Int, _ ablPointer: UnsafeMutableAudioBufferListPointer, _ frameCount: AVAudioFrameCount) {
        let frames = Int(frameCount)
        let bytes = frames * MemoryLayout<Float32>.size
        src.withUnsafeBytes { rawPtr in
            for (ch, buffer) in ablPointer.enumerated() {
                guard let dest = buffer.mData else { continue }
                let srcBase = rawPtr.baseAddress!.advanced(by: offset + ch * bytes)
                memcpy(dest, srcBase, bytes)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func convertFLT(_ src: [UInt8], _ offset: Int, _ ablPointer: UnsafeMutableAudioBufferListPointer, _ frameCount: AVAudioFrameCount) {
        let frames = Int(frameCount)
        let channelCount = ablPointer.count
        src.withUnsafeBytes { rawPtr in
            let srcPtr = rawPtr.baseAddress!
                .advanced(by: offset)
                .assumingMemoryBound(to: Float32.self)
            for (ch, buffer) in ablPointer.enumerated() {
                guard let dest = buffer.mData else { continue }
                let destPtr = dest.assumingMemoryBound(to: Float32.self)
                for frame in 0 ..< frames {
                    destPtr[frame] = srcPtr[frame * channelCount + ch]
                }
            }
        }
    }
}
