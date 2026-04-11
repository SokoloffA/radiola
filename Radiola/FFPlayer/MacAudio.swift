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
    private var nextPresentationTime = CMTime.zero
    private var rendererStarted = false
    private var prerollBuffersQueued = 0
    private let prerollTargetBuffers = 8
    private var prerollStartTime: CMTime?
    private let playbackQueue = DispatchQueue(label: "MacAudioPlaybackQueue")

    private let ringBuffer: RingBuffer
    let numBuffers: Int

    private var avFormat: AVAudioFormat?

    private var pcmBuffer = PcmBuffer(capacity: 65536)

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
        self.avFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Double(ffFormat.sampleRate),
            channels: AVAudioChannelCount(ffFormat.channelsNum),
            interleaved: true
        )

        guard let avFormat = avFormat else {
            throw NSError(code: .formatError, message: internalErrorDescription, debug: "Failed to create AVAudioFormat from FFDecoder.Format")
        }

        debug("FFFormat: \(ffFormat))")
        debug("AVFormat: \(avFormat)")

        let renderer = AVSampleBufferAudioRenderer()

        let synchronizer = AVSampleBufferRenderSynchronizer()
        synchronizer.addRenderer(renderer)
        if #available(macOS 11.3, *) {
            synchronizer.delaysRateChangeUntilHasSufficientMediaData = true
        }
        synchronizer.rate = 0.0

        audioRenderer = renderer
        renderSynchronizer = synchronizer
        nextPresentationTime = .zero
        rendererStarted = false
        prerollBuffersQueued = 0
        prerollStartTime = nil

        if let audioDevice = audioDevice {
            setOutputDevice(audioDevice: audioDevice)
        }

        setVolume(0)

        renderer.requestMediaDataWhenReady(on: playbackQueue) { [weak self] in
            self?.feedAudioRenderer()
        }

        rendererFlushObserver = NotificationCenter.default.addObserver(
            forName: .AVSampleBufferAudioRendererWasFlushedAutomatically,
            object: renderer,
            queue: nil
        ) { [weak self] _ in
            self?.playbackQueue.async { self?.realignAfterFlush() }
        }

        if #available(macOS 12.0, *) {
            NotificationCenter.default.addObserver(
                forName: .AVSampleBufferAudioRendererOutputConfigurationDidChange,
                object: renderer,
                queue: nil
            ) { [weak self] _ in
                self?.playbackQueue.async { self?.routeChanged() }
            }
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
        if let synchronizer = renderSynchronizer {
            synchronizer.rate = 0.0
            renderSynchronizer = nil
        }
        if let renderer = audioRenderer {
            renderer.stopRequestingMediaData()
            renderer.flush()
            audioRenderer = nil
        }
        pcmBuffer.reset()
        avFormat = nil
        rendererStarted = false
        prerollBuffersQueued = 0
        prerollStartTime = nil
        nextPresentationTime = .zero
    }

    /* ****************************************
     *
     * ****************************************/
    private func feedAudioRenderer() {
        guard
            let renderer = audioRenderer,
            let synchronizer = renderSynchronizer else {
            return
        }

        var enqueuedNow = 0
        while renderer.isReadyForMoreMediaData {
            guard let sampleBuffer = dequeueAudioSampleBuffer() else { break }
            if prerollStartTime == nil { prerollStartTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer) }
            renderer.enqueue(sampleBuffer)
            prerollBuffersQueued += 1
            enqueuedNow += 1

            if !rendererStarted && prerollBuffersQueued >= prerollTargetBuffers {
                startSynchronizer(synchronizer, at: prerollStartTime ?? nextPresentationTime)
                rendererStarted = true
            }
            if enqueuedNow >= 64 { break }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func dequeueAudioSampleBuffer() -> CMSampleBuffer? {
        guard let avFormat else { return nil }
        let bytesPerFrame = Int(avFormat.streamDescription.pointee.mBytesPerFrame)
        guard bytesPerFrame > 0 else { return nil }
        guard let index = ringBuffer.readIndex() else { return nil }

        let src = ringBuffer.buffers[index]
        let byteCount = src.audioDataByteSize
        guard byteCount > 0 else { ringBuffer.incReadIndex(); return nil }

        let data = Array(src.audioData[0 ..< byteCount])
        ringBuffer.incReadIndex()

        let availableFrames = byteCount / bytesPerFrame
        guard availableFrames > 0 else { return nil }

        var blockBuffer: CMBlockBuffer?
        guard CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault, memoryBlock: nil, blockLength: byteCount,
            blockAllocator: kCFAllocatorDefault, customBlockSource: nil,
            offsetToData: 0, dataLength: byteCount, flags: 0, blockBufferOut: &blockBuffer
        ) == noErr, let blockBuffer else { return nil }

        let writeOK = data.withUnsafeBytes { raw -> Bool in
            guard let base = raw.baseAddress else { return false }
            return CMBlockBufferReplaceDataBytes(with: base, blockBuffer: blockBuffer,
                                                 offsetIntoDestination: 0, dataLength: byteCount) == noErr
        }
        guard writeOK else { return nil }

        let formatDescription = avFormat.formatDescription
        var sampleBuffer: CMSampleBuffer?
        let pts = nextPresentationTime
        guard CMAudioSampleBufferCreateReadyWithPacketDescriptions(
            allocator: kCFAllocatorDefault, dataBuffer: blockBuffer,
            formatDescription: formatDescription, sampleCount: availableFrames,
            presentationTimeStamp: pts, packetDescriptions: nil,
            sampleBufferOut: &sampleBuffer
        ) == noErr, let sampleBuffer else { return nil }

        let timescale = CMTimeScale(max(1, avFormat.sampleRate))
        nextPresentationTime = CMTimeAdd(pts, CMTime(value: CMTimeValue(availableFrames), timescale: timescale))
        return sampleBuffer
    }

    /* ****************************************
     *
     * ****************************************/
    private func startSynchronizer(_ synchronizer: AVSampleBufferRenderSynchronizer, at time: CMTime) {
        let t = CMTimeCompare(time, .zero) >= 0 ? time : .zero
        if #available(macOS 11.3, *) {
            let hostStart = CMTimeAdd(CMClockGetTime(CMClockGetHostTimeClock()),
                                      CMTime(seconds: 0.2, preferredTimescale: 1000))
            synchronizer.setRate(1.0, time: t, atHostTime: hostStart)
        } else {
            synchronizer.setRate(1.0, time: t)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func realignAfterFlush() {
        guard
            let renderer = audioRenderer,
            let synchronizer = renderSynchronizer else {
            return
        }

        renderer.flush()
        let current = synchronizer.currentTime()
        synchronizer.rate = 0.0
        nextPresentationTime = CMTimeCompare(current, .zero) >= 0 ? current : .zero
        prerollBuffersQueued = 0
        prerollStartTime = nil
        rendererStarted = false
        feedAudioRenderer() // ← без этого тишина
    }

    /* ****************************************
     *
     * ****************************************/
    func routeChanged() {
        playbackQueue.async { [weak self] in
            guard
                let self,
                let renderer = self.audioRenderer,
                let synchronizer = self.renderSynchronizer else {
                return
            }

            renderer.flush()
            let current = synchronizer.currentTime()
            synchronizer.rate = 0.0
            self.nextPresentationTime = CMTimeCompare(current, .zero) >= 0 ? current : .zero
            self.prerollBuffersQueued = 0
            self.prerollStartTime = nil
            self.rendererStarted = false
            self.feedAudioRenderer()
        }
    }

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
    private func setOutputDevice(audioDevice: AudioDevice) {
        guard let renderer = audioRenderer else { return }
        if #available(macOS 10.13, *) {
            renderer.audioOutputDeviceUniqueID = audioDevice.UID
            routeChanged()
        }
    }
}
