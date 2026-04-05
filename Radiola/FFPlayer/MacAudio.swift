//
//  MacAudio.swift
//  Radiola
//
//  Created by Alex Sokolov on 15.03.2026.
//

import Accelerate
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

    private var pcmBuffer = PcmBuffer(capacity: 65536)

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

        debug("FFFormat: \(ffFormat))")
        debug("AVFormat: \(avFormat)")

        let engine = AVAudioEngine()
        self.engine = engine

        configurationChangeObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: nil
        ) { [weak self] _ in
            self?.handleEngineConfigurationChange()
        }

        setVolume(0)

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
        guard let ffFormat = ffFormat else { return }
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let channelCount = ablPointer.count
        let bytesNeeded = channelCount * Int(frameCount) * ffFormat.bytesPerSample

        while pcmBuffer.available < bytesNeeded {
            guard let index = ringBuffer.readIndex() else { break }
            let src = ringBuffer.buffers[index]
            src.audioData.withUnsafeBytes { rawPtr in
                pcmBuffer.write(rawPtr.baseAddress!, src.audioDataByteSize)
            }
            ringBuffer.incReadIndex()
        }

        guard let ptr = pcmBuffer.readPointer(bytes: bytesNeeded) else { return }
        convertBytes(ptr, ablPointer, frameCount)
        pcmBuffer.consume(bytesNeeded)
    }

    /* ****************************************
     * deinterleave via vDSP_vsadd with a channelCount step
     * ****************************************/
    private func convertBytes(_ src: UnsafeRawPointer, _ ablPointer: UnsafeMutableAudioBufferListPointer, _ frameCount: AVAudioFrameCount) {
        let frames = Int(frameCount)
        let channelCount = ablPointer.count
        let srcPtr = src.assumingMemoryBound(to: Float32.self)
        for (ch, buffer) in ablPointer.enumerated() {
            guard let dest = buffer.mData else { continue }
            let destPtr = dest.assumingMemoryBound(to: Float32.self)
            // deinterleave via vDSP_vsadd with a channelCount step
            vDSP_mmov(srcPtr.advanced(by: ch), destPtr, 1, vDSP_Length(frames), vDSP_Length(channelCount), 1)
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

        pcmBuffer.reset()
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
}
