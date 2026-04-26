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
    private var audioRenderer: AVSampleBufferAudioRenderer?
    private var renderSynchronizer: AVSampleBufferRenderSynchronizer?
    private var rendererFlushObserver: NSObjectProtocol?
    private var rendererOutputConfigObserver: NSObjectProtocol?
    private let playbackQueue = DispatchQueue(label: "MacAudioPlaybackQueue")

    private let timeline = AudioTimeline()

    private let ringBuffer: RingBuffer
    let numBuffers: Int

    private var avFormat: AVAudioFormat?
    private var bytesPerFrame = 0
    private var ringBufferDuration: TimeInterval = 0

    private var isRealigned = true

    var onNeedRestart: (() -> Void)?

    private var speedMetric: SpeedMetric?
    private var renderCountMetric: CounterMetric?

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
        // renderCountMetric = CounterMetric(name: "MacAudio render count")
        // speedMetric = SpeedMetric(name: "MacAudio speed")

        self.avFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Double(ffFormat.sampleRate),
            channels: AVAudioChannelCount(ffFormat.channelsNum),
            interleaved: true
        )

        guard let avFormat = avFormat else {
            throw NSError(code: .formatError, message: internalErrorDescription, debug: "Failed to create AVAudioFormat from FFDecoder.Format")
        }

        bytesPerFrame = Int(avFormat.streamDescription.pointee.mBytesPerFrame)
        guard bytesPerFrame > 0 else {
            throw NSError(code: .formatError, message: internalErrorDescription, debug: "Incorrect audio format bytesPerFrame=\(bytesPerFrame)")
        }
        ringBufferDuration = Double(ringBuffer.bufferSize / bytesPerFrame) / avFormat.sampleRate

        debug("FFFormat: \(ffFormat))")
        debug("AVFormat: \(avFormat)")

        let renderer = AVSampleBufferAudioRenderer()

        let synchronizer = AVSampleBufferRenderSynchronizer()
        synchronizer.addRenderer(renderer)
        synchronizer.delaysRateChangeUntilHasSufficientMediaData = true
        synchronizer.rate = 0.0

        audioRenderer = renderer
        renderSynchronizer = synchronizer
        timeline.reset()

        if let audioDevice = audioDevice {
            setOutputDevice(audioDevice: audioDevice)
        }

        setVolume(0)

        rendererFlushObserver = NotificationCenter.default.addObserver(
            forName: .AVSampleBufferAudioRendererWasFlushedAutomatically,
            object: renderer,
            queue: nil
        ) { [weak self] _ in
            self?.playbackQueue.async { self?.onNeedRestart?() }
        }

        if #available(macOS 12.0, *) {
            rendererOutputConfigObserver = NotificationCenter.default.addObserver(
                forName: .AVSampleBufferAudioRendererOutputConfigurationDidChange,
                object: renderer,
                queue: nil
            ) { [weak self] _ in
                self?.playbackQueue.async { self?.onNeedRestart?() }
            }
        }

        playbackQueue.async { [weak self] in
            self?.feedAudioRenderer()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func stop() {
        if let observer = rendererFlushObserver {
            NotificationCenter.default.removeObserver(observer)
            rendererFlushObserver = nil
        }

        if let observer = rendererOutputConfigObserver {
            NotificationCenter.default.removeObserver(observer)
            rendererOutputConfigObserver = nil
        }

        if let synchronizer = renderSynchronizer {
            synchronizer.rate = 0.0
            renderSynchronizer = nil
        }

        if let renderer = audioRenderer {
            renderer.flush()
            audioRenderer = nil
        }

        avFormat = nil
        timeline.reset()
    }

    /* ****************************************
     *
     * ****************************************/
    private func feedAudioRenderer() {
        guard
            let renderer = audioRenderer,
            let synchronizer = renderSynchronizer else { return }

        var duration = 0.0
        while renderer.isReadyForMoreMediaData {
            if isRealigned && ringBuffer.readyNum() < 50 { break }
            isRealigned = false

            guard let sampleBuffer = dequeueAudioSampleBuffer() else { break }
            duration += CMSampleBufferGetOutputDuration(sampleBuffer).seconds

            if timeline.prerollStartTime == nil {
                timeline.prerollStartTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            }

            renderer.enqueue(sampleBuffer)
            timeline.buffersQueued += 1

            if !timeline.isStarted && timeline.buffersQueued >= timeline.prerollTarget {
                startSynchronizer(synchronizer, at: timeline.prerollStartTime ?? timeline.nextPresentationTime)
                timeline.isStarted = true
            }
        }

        let delay = (duration > 0 ? duration : ringBufferDuration) * 0.8

        playbackQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.feedAudioRenderer()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func dequeueAudioSampleBuffer() -> CMSampleBuffer? {
        renderCountMetric?.record(1)

        guard let avFormat else { return nil }
        guard let index = ringBuffer.readIndex() else { return nil }

        let src = ringBuffer.buffers[index]
        let byteCount = src.audioDataByteSize
        guard byteCount > 0 else {
            ringBuffer.incReadIndex()
            return nil
        }

        let availableFrames = byteCount / bytesPerFrame
        guard availableFrames > 0 else { return nil }

        var ok: OSStatus
        var blockBuffer: CMBlockBuffer?
        ok = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: byteCount,
            blockAllocator: kCFAllocatorDefault,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: byteCount,
            flags: 0,
            blockBufferOut: &blockBuffer
        )

        guard ok == noErr, let blockBuffer else { return nil }

        ok = src.audioData.withUnsafeBytes { raw -> OSStatus in
            guard let base = raw.baseAddress else { return -1 }

            return CMBlockBufferReplaceDataBytes(
                with: base,
                blockBuffer: blockBuffer,
                offsetIntoDestination: 0,
                dataLength: byteCount
            )
        }

        guard ok == noErr else { return nil }

        ringBuffer.incReadIndex()

        var sampleBuffer: CMSampleBuffer?
        let pts = timeline.nextPresentationTime
        guard CMAudioSampleBufferCreateReadyWithPacketDescriptions(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            formatDescription: avFormat.formatDescription,
            sampleCount: availableFrames,
            presentationTimeStamp: pts,
            packetDescriptions: nil,
            sampleBufferOut: &sampleBuffer
        ) == noErr, let sampleBuffer else { return nil }

        let sampleRate = avFormat.streamDescription.pointee.mSampleRate
        timeline.advance(by: availableFrames, sampleRate: sampleRate)

        speedMetric?.record(byteCount)

        return sampleBuffer
    }

    /* ****************************************
     *
     * ****************************************/
    private func startSynchronizer(_ synchronizer: AVSampleBufferRenderSynchronizer, at time: CMTime) {
        let t = CMTimeCompare(time, .zero) >= 0 ? time : .zero
        let hostStart = CMTimeAdd(CMClockGetTime(CMClockGetHostTimeClock()), CMTime(seconds: 0.2, preferredTimescale: 1000))
        synchronizer.setRate(1.0, time: t, atHostTime: hostStart)
    }

    /* ****************************************
     *
     * ****************************************/
//    private func realignAfterFlush() {
//        audioRenderer?.flush()
//        guard let synchronizer = renderSynchronizer else { return }
//
//        let current = synchronizer.currentTime()
//        synchronizer.rate = 0.0
//        timeline.reset(at: current)
//
//        isRealigned = true
//        feedAudioRenderer()
//    }

    /* ****************************************
     *
     * ****************************************/
    func setVolume(_ volume: Float) {
        audioRenderer?.volume = volume
    }

    /* ****************************************
     *
     * ****************************************/
    func fadeInVolume(to targetVolume: Float, duration: TimeInterval = 0.1) {
        let steps = 20
        let stepDuration = duration / Double(steps)

        for i in 1 ... steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                self?.audioRenderer?.volume = targetVolume * Float(i) / Float(steps)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    public func setOutputDevice(audioDevice: AudioDevice) {
        if #available(macOS 10.13, *) {
            playbackQueue.async { [weak self] in
                self?.audioRenderer?.audioOutputDeviceUniqueID = audioDevice.UID
            }
        }
    }
}

// MARK: - AudioTimeline

private class AudioTimeline {
    var nextPresentationTime = CMTime.zero
    var prerollStartTime: CMTime?
    var buffersQueued = 0
    var isStarted = false
    let prerollTarget: Int

    /* ****************************************
     *
     * ****************************************/
    init(prerollTarget: Int = 8) {
        self.prerollTarget = prerollTarget
    }

    /* ****************************************
     *
     * ****************************************/
    func reset() {
        reset(at: .zero)
    }

    /* ****************************************
     *
     * ****************************************/
    func reset(at time: CMTime) {
        nextPresentationTime = CMTimeCompare(time, .zero) >= 0 ? time : .zero
        prerollStartTime = nil
        buffersQueued = 0
        isStarted = false
    }

    /* ****************************************
     *
     * ****************************************/
    func advance(by frames: Int, sampleRate: Double) {
        let duration = CMTime(
            value: CMTimeValue(frames),
            timescale: CMTimeScale(sampleRate)
        )
        nextPresentationTime = CMTimeAdd(nextPresentationTime, duration)
    }
}
