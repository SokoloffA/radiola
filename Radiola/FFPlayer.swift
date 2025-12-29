//
//  FFPlayer.swift
//  Radiola
//
//  Created by Alex Sokolov on 08.06.2025.
//

import AudioToolbox
import FFAudio
import Foundation

fileprivate let NUM_AUDIO_BUFFERS = 50
fileprivate let NUM_RING_BUFFERS = 500
fileprivate let BUFFER_SIZE = 8192

let internalErrorDescription = NSLocalizedString("Internal error.\nSee logs for more information.", comment: "Player error message")
let invalidURLErrorDescription = NSLocalizedString("The station is temporarily unavailable. Check URL or try again later.", comment: "Player error message")
let timeoutErrorDescription = NSLocalizedString("Cannot play station. Your internet connection may be too slow or unstable.", comment: "Player error message")

extension FFPlayer {
    enum ErrorCode: Int32 {
        case noError = 0
        case alocError_avframe
        case alocError_avpacket
        case alocError_avcodec
        case alocError_avformat
        case alocError_AudioQueue
        case alocError_AudioQueueBuffer
        case noStreamFoundError
        case noCodecFoundError
        case audioQueueStartError
        case audioQueueStopError
        case setVolumeError
        case setDeviceError
        case timeoutError
        case playlistDownloadError
        case playlistEmptyResponse
        case playlistInvalidData
    }
}

extension FFPlayer {
    enum State {
        case stoped
        case connecting
        case playing
        case error

        var description: String {
            switch self {
                case .stoped: return "stoped"
                case .connecting: return "connecting"
                case .playing: return "playing"
                case .error: return "error"
            }
        }
    }
}

// MARK: - FFPlayer

public class FFPlayer: ObservableObject {
    private var backend: Backend!

    @Published fileprivate(set) var state = State.stoped
    @Published fileprivate(set) var nowPlaing: String?
    fileprivate(set) var error: NSError?

    var volume: Float = 1.0 {
        didSet { updateVolume() }
    }

    var isMuted: Bool = false {
        didSet { updateVolume() }
    }

    private(set) var audioDeviceUID: String?

    /* ****************************************
     *
     * ****************************************/
    init() {
        backend = Backend(frontend: self)
    }

    /* ****************************************
     *
     * ****************************************/
    func play(url: URL, audioDeviceUID: String?) {
        error = nil

        let vol = isMuted ? 0.0 : volume
        self.audioDeviceUID = audioDeviceUID
        let deviceUID = audioDeviceUID

        backend.queue.async {
            self.backend.userInterrupt.value = false
            self.backend.shouldInterrupt.value = false
            self.backend.start(url: url, volume: vol, deviceUID: deviceUID)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func stop() {
        backend.userInterrupt.value = true
        backend.shouldInterrupt.value = true

        backend.queue.async {
            self.backend.setVolume(0)
            self.backend.stop()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func updateVolume() {
        let vol = isMuted ? 0.0 : volume
        backend.queue.async {
            self.backend.setVolume(vol)
        }
    }
}

// MARK: - RingBuffer

fileprivate class RingBuffer {
    class Buffer {
        var audioData = [UInt8](repeating: 0, count: BUFFER_SIZE)
        var audioDataByteSize: Int = 0
    }

    var buffers: [Buffer]

    private var _readIndex: Int64 = 0
    private var _writeIndex: Int64 = 0
    private var mutex = pthread_mutex_t()

    /* ****************************************
     *
     * ****************************************/
    init() {
        buffers = (0 ..< NUM_RING_BUFFERS).map { _ in Buffer() }
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

// MARK: - Backend

fileprivate class Backend {
    unowned let frontend: FFPlayer
    fileprivate let queue = DispatchQueue(label: "FFPlayerQueue")

    var formatContext: UnsafeMutablePointer<AVFormatContext>!
    var streamIndex: Int = -1
    var codecContext: UnsafeMutablePointer<AVCodecContext>!
    var swrContext: OpaquePointer!
    var outLayout = AVChannelLayout()
    var outSampleRate: Int32 = 0
    var outChannels: Int32 = 0

    var audioQueue: AudioQueueRef?
    let outFmt: AVSampleFormat = AV_SAMPLE_FMT_FLT

    var frame: UnsafeMutablePointer<AVFrame>!
    var packet: UnsafeMutablePointer<AVPacket>!

    var pcmBuffer = [UInt8]()
    private var audioQueueBuffers = [AudioQueueBufferRef?](repeating: nil, count: NUM_AUDIO_BUFFERS)

    var prevNowPlaying = ""

    let userInterrupt = AtomicBool()
    let shouldInterrupt = AtomicBool()
    var interruptCB: AVIOInterruptCB!

    let ringBuffer = RingBuffer()
    private var ffmpegThread: Thread?

    /* ****************************************
     *
     * ****************************************/
    init(frontend: FFPlayer) {
        self.frontend = frontend
        frame = av_frame_alloc()
        packet = av_packet_alloc()

        let opaque = Unmanaged.passUnretained(self).toOpaque()
        interruptCB = AVIOInterruptCB(callback: interruptCallback, opaque: opaque)
    }

    /* ****************************************
     *
     * ****************************************/
    deinit {
        stop()

        if packet != nil {
            av_packet_free(&packet)
        }

        if frame != nil {
            av_frame_free(&frame)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func start(url: URL, volume: Float, deviceUID: String?) {
        do {
            setState(.connecting)

            if PlayList.isPlayListURL(url) {
                let playList = PlayList()
                try playList.download(url: url)

                try load(url: playList.urls[0])
            } else {
                try load(url: url)
            }

            setVolume(volume)
            try startAudioQueue(deviceUID: deviceUID)

            setState(.playing)
        } catch {
            setError(error as NSError)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func stop() {
        shouldInterrupt.value = true

        if let audioQueue = audioQueue {
            AudioQueueStop(audioQueue, true)
            AudioQueueDispose(audioQueue, true)
            self.audioQueue = nil
        }

        while let thread = ffmpegThread, thread.isExecuting {
            Thread.sleep(forTimeInterval: 0.01)
        }

        if swrContext != nil {
            swr_free(&swrContext)
            swrContext = nil
        }

        if codecContext != nil {
            avcodec_free_context(&codecContext)
            codecContext = nil
        }

        if formatContext != nil {
            avformat_close_input(&formatContext)
            formatContext = nil
        }

        av_channel_layout_uninit(&outLayout)

        prevNowPlaying = ""

        Task.detached { @MainActor in
            if self.frontend.state != .stoped { self.frontend.state = .stoped }
            if self.frontend.nowPlaing != "" { self.frontend.nowPlaing = "" }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func load(url: URL) throws {
        debug("FFplayer load \(url)")
        setupFFmpegLogging()

        ringBuffer.reset()

        if frame == nil {
            throw NSError(code: .alocError_avframe, message: internalErrorDescription, debug: "Error calling av_frame_alloc")
        }

        if packet == nil {
            throw NSError(code: .alocError_avpacket, message: internalErrorDescription, debug: "Error calling av_packet_alloc")
        }

        var options: OpaquePointer?
        var err: Int32 = 0

        err = av_dict_set(&options, "icy", "1", 0)
        if err < 0 {
            throw NSError(ffCode: err, message: internalErrorDescription, debug: "Error calling av_dict_set")
        }

        formatContext = avformat_alloc_context()
        guard formatContext != nil else {
            throw NSError(code: .alocError_avformat, message: internalErrorDescription, debug: "Error calling avformat_alloc_context")
        }

        formatContext.pointee.interrupt_callback = interruptCB

        err = avformat_open_input(&formatContext, url.absoluteString, nil, &options)
        if err < 0 {
            av_dict_free(&options)
            throw NSError(ffCode: err, message: invalidURLErrorDescription, debug: "Error calling avformat_open_input")
        }
        av_dict_free(&options)

        err = avformat_find_stream_info(formatContext, nil)
        if err < 0 {
            throw NSError(ffCode: err, message: invalidURLErrorDescription, debug: "Error calling avformat_find_stream_info")
        }

        // Find the first audio stream
        streamIndex = Int(av_find_best_stream(formatContext, AVMEDIA_TYPE_AUDIO, -1, -1, nil, 0))
        if streamIndex < 0 {
            throw NSError(code: .noStreamFoundError, message: invalidURLErrorDescription, debug: "No audio stream found.")
        }

        guard let stream = formatContext.pointee.streams[streamIndex] else {
            throw NSError(code: .noStreamFoundError, message: invalidURLErrorDescription, debug: "No input stream found.")
        }

        guard
            let codecParams = stream.pointee.codecpar, // formatContext.pointee.streams[streamIndex]!.pointee.codecpar,
            let codec = avcodec_find_decoder(codecParams.pointee.codec_id)
        else {
            throw NSError(code: .noCodecFoundError, message: invalidURLErrorDescription, debug: "No input codec found.")
        }

        codecContext = avcodec_alloc_context3(codec)
        if codecContext == nil {
            throw NSError(code: .alocError_avcodec, message: invalidURLErrorDescription, debug: "Error calling avcodec_alloc_context3")
        }

        codecContext.pointee.pkt_timebase = stream.pointee.time_base

        err = avcodec_parameters_to_context(codecContext, stream.pointee.codecpar)
        if err < 0 {
            throw NSError(ffCode: err, message: invalidURLErrorDescription, debug: "Error calling avcodec_parameters_to_context")
        }

        err = avcodec_open2(codecContext, codec, nil)
        if err < 0 {
            throw NSError(ffCode: err, message: invalidURLErrorDescription, debug: "Error calling avcodec_open2")
        }

        // Define output format ................
        outSampleRate = codecContext.pointee.sample_rate
        outChannels = min(2, codecContext.pointee.ch_layout.nb_channels)

        withUnsafeMutablePointer(to: &outLayout) { outLayoutPtr in
            av_channel_layout_default(outLayoutPtr, outChannels)

            err = swr_alloc_set_opts2(&swrContext,
                                      outLayoutPtr,
                                      outFmt,
                                      outSampleRate,
                                      &codecContext.pointee.ch_layout, codecContext.pointee.sample_fmt, codecContext.pointee.sample_rate,
                                      0, nil)
        }
        if err < 0 {
            throw NSError(ffCode: err, message: invalidURLErrorDescription, debug: "Error calling swr_alloc_set_opts2")
        }

        err = swr_init(swrContext)
        if err < 0 {
            throw NSError(ffCode: err, message: invalidURLErrorDescription, debug: "Error calling swr_init")
        }

        var format = makeASBD(outFmt: outFmt, outChannels: UInt32(outChannels), outSampleRate: Double(outSampleRate))

        err = AudioQueueNewOutput(
            &format,
            fillAudioQueueBuffer,
            Unmanaged.passUnretained(self).toOpaque(),
            nil,
            nil,
            0,
            &audioQueue)

        if err < 0 {
            throw NSError(code: .alocError_AudioQueue, message: internalErrorDescription, debug: "Error calling AudioQueueNewOutput")
        }

        // Preload audio
        for i in 0 ..< NUM_AUDIO_BUFFERS {
            var buffer: AudioQueueBufferRef?
            err = AudioQueueAllocateBuffer(audioQueue!, UInt32(BUFFER_SIZE), &buffer)

            if err != noErr || buffer == nil {
                throw NSError(code: .alocError_AudioQueueBuffer, message: internalErrorDescription, debug: "Error calling AudioQueueAllocateBuffer")
            }

            try decodeBuffer(backend: self, outBuffer: ringBuffer.buffers[i])
            ringBuffer.incWriteIndex()

            audioQueueBuffers[i] = buffer
            fillAudioQueueBuffer(userData: Unmanaged.passUnretained(self).toOpaque(), outAQ: audioQueue!, outBuffer: buffer!)
        }

        // Start ffmpeg decoder thread
        let delay = bufferDuration(format: format)

        ffmpegThread = Thread { [weak self, delay] in
            decode(backend: self!, delay: delay)
        }

        ffmpegThread?.name = "FFmpegDecoder"
        ffmpegThread?.qualityOfService = .userInitiated
        ffmpegThread?.start()
    }

    /* ****************************************
     *
     * ****************************************/
    private func setupFFmpegLogging() {
        av_log_set_level(AV_LOG_INFO)

        av_log_set_callback { _, level, format, args in
            if level > AV_LOG_INFO { return }
            guard let format = format else { return }
            guard let args = args else { return }

            var buffer = [CChar](repeating: 0, count: 4096)
            vsnprintf(&buffer, buffer.count, format, args)
            var message = String(cString: buffer)
            message = message.trimmingCharacters(in: .whitespacesAndNewlines)

            if !message.isEmpty {
                debug("[FFmpeg] \(Backend.ffmpegLogLevelToString(level)): \(message)")
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private static func ffmpegLogLevelToString(_ level: Int32) -> String {
        switch level {
            case AV_LOG_PANIC: return "PANIC"
            case AV_LOG_FATAL: return "FATAL"
            case AV_LOG_ERROR: return "ERROR"
            case AV_LOG_WARNING: return "WARNING"
            case AV_LOG_INFO: return "INFO"
            case AV_LOG_VERBOSE: return "VERBOSE"
            case AV_LOG_DEBUG: return "DEBUG"
            case AV_LOG_TRACE: return "TRACE"
            default: return "UNKNOWN(\(level))"
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func makeASBD(outFmt: AVSampleFormat, outChannels: UInt32, outSampleRate: Double) -> AudioStreamBasicDescription {
        var format = AudioStreamBasicDescription()
        format.mSampleRate = outSampleRate
        format.mFormatID = kAudioFormatLinearPCM

        // sample type detection
        switch outFmt {
            case AV_SAMPLE_FMT_FLT, AV_SAMPLE_FMT_FLTP:
                format.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked
                format.mBitsPerChannel = 32

            case AV_SAMPLE_FMT_S16, AV_SAMPLE_FMT_S16P:
                format.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
                format.mBitsPerChannel = 16

            case AV_SAMPLE_FMT_S32, AV_SAMPLE_FMT_S32P:
                format.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
                format.mBitsPerChannel = 32

            case AV_SAMPLE_FMT_U8, AV_SAMPLE_FMT_U8P:
                format.mFormatFlags = kAudioFormatFlagIsPacked
                format.mBitsPerChannel = 8

            default:
                // std::cerr << "Unsupported sample format: " << av_get_sample_fmt_name(outFmt) << std::endl;
                format.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
                format.mBitsPerChannel = 16
        }

        format.mChannelsPerFrame = outChannels
        format.mFramesPerPacket = 1
        format.mBytesPerFrame = (format.mBitsPerChannel / 8) * format.mChannelsPerFrame
        format.mBytesPerPacket = format.mBytesPerFrame
        format.mReserved = 0

        return format
    }

    /* ****************************************
     *
     * ****************************************/
    private func bufferDuration(format: AudioStreamBasicDescription) -> TimeInterval {
        var bytesPerFrame = Int(format.mBytesPerFrame)
        if bytesPerFrame == 0 {
            bytesPerFrame = 44100 * 2
        }

        let frames = Double(BUFFER_SIZE) / Double(bytesPerFrame)
        return frames / format.mSampleRate
    }

    /* ****************************************
     *
     * ****************************************/
    func startAudioQueue(deviceUID: String?) throws {
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

        let err = AudioQueueStart(audioQueue, nil)
        if err != noErr {
            throw NSError(code: .audioQueueStartError, error: err, message: internalErrorDescription, debug: "Error calling AudioQueueStart")
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func setState(_ state: FFPlayer.State) {
        Task.detached { @MainActor in
            if self.frontend.state != state { self.frontend.state = state }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func setVolume(_ volume: Float) {
        guard let audioQueue = audioQueue else { return }

        let err = AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, volume)
        if err != noErr {
            setError(NSError(code: .setVolumeError, error: err, message: internalErrorDescription, debug: "Error calling AudioQueueSetParameter"))
        }
    }

    /* ****************************************
     *
     * ****************************************/
    fileprivate func setError(_ error: NSError) {
        if userInterrupt.value || error.code == averror_exit {
            stop()
            setState(.stoped)
            return
        }

        Task { @MainActor in
            self.frontend.error = error
            self.frontend.state = .error
        }
        stop()
    }
}

// MARK: - FFMpeg callbacks

/* ****************************************
 *
 * ****************************************/
fileprivate func decode(backend: Backend, delay: TimeInterval) {
    do {
        while true {
            if backend.shouldInterrupt.value {
                return
            }

            guard let index = backend.ringBuffer.writeIndex() else {
                Thread.sleep(forTimeInterval: delay)
                continue
            }

            try decodeBuffer(backend: backend, outBuffer: backend.ringBuffer.buffers[index])
            backend.ringBuffer.incWriteIndex()
        }
    } catch {
        warning(error)
        backend.queue.async {
            backend.setError(error as NSError)
        }
    }
}

/* ****************************************
 *
 * ****************************************/
fileprivate func decodeBuffer(backend: Backend, outBuffer: RingBuffer.Buffer) throws {
    var timeoutCount = 0
    let maxTimeouts = 10

    var err: Int32 = 0

    while backend.pcmBuffer.count < BUFFER_SIZE {
        err = av_read_frame(backend.formatContext, backend.packet)
        if err == -ETIMEDOUT {
            debug("Error calling av_read_frame: ETIMEDOUT")
            timeoutCount += 1
            if timeoutCount >= maxTimeouts {
                throw NSError(ffCode: err, message: timeoutErrorDescription, debug: "Too many timeouts from av_read_frame")
            }
            continue
        }

        if err < 0 {
            throw NSError(ffCode: err, message: timeoutErrorDescription, debug: "Error calling av_read_frame")
        }

        timeoutCount = 0

        defer {
            av_packet_unref(backend.packet)
        }
        readMetadta(backend: backend, tag: av_dict_get(backend.formatContext.pointee.metadata, "StreamTitle", nil, 0))

        if backend.packet.pointee.stream_index != backend.streamIndex {
            continue
        }

        err = avcodec_send_packet(backend.codecContext, backend.packet)
        if err < 0 {
            throw NSError(ffCode: err, message: internalErrorDescription, debug: "Error calling avcodec_send_packet")
        }

        err = avcodec_receive_frame(backend.codecContext, backend.frame)
        if err == -EAGAIN {
            continue
        } else if err < 0 {
            throw NSError(ffCode: err, message: internalErrorDescription, debug: "Error calling avcodec_receive_frame")
        }

        let dstNbSamples = av_rescale_rnd(
            swr_get_delay(backend.swrContext, Int64(backend.codecContext.pointee.sample_rate)) + Int64(backend.frame.pointee.nb_samples),
            Int64(backend.outSampleRate),
            Int64(backend.codecContext.pointee.sample_rate),
            AV_ROUND_UP)

        var outLinesize: Int32 = 0
        var outBuf: UnsafeMutablePointer<UInt8>?
        err = av_samples_alloc(&outBuf, &outLinesize, backend.outChannels, Int32(dstNbSamples), backend.outFmt, 0)
        guard
            err >= 0,
            var outBuf = outBuf
        else {
            throw NSError(ffCode: err, message: internalErrorDescription, debug: "Error calling av_samples_alloc")
        }
        defer {
            av_freep(&outBuf)
        }

        let outBufPointer = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>.allocate(capacity: 1)
        outBufPointer.initialize(to: outBuf)
        defer {
            outBufPointer.deinitialize(count: 1)
            outBufPointer.deallocate()
        }

        let srcData = withUnsafePointer(to: &backend.frame.pointee.data) {
            UnsafeRawPointer($0).assumingMemoryBound(to: UnsafePointer<UInt8>?.self)
        }

        let samplesConverted = swr_convert(backend.swrContext,
                                           outBufPointer,
                                           Int32(dstNbSamples),
                                           srcData,
                                           backend.frame.pointee.nb_samples)

        if samplesConverted < 0 {
            throw NSError(ffCode: samplesConverted, message: internalErrorDescription, debug: "Error calling swr_convert")
        }

        let outSize = av_samples_get_buffer_size(nil, backend.outChannels, samplesConverted, backend.outFmt, 1)
        if outSize < 0 {
            throw NSError(ffCode: outSize, message: internalErrorDescription, debug: "Error calling av_samples_get_buffer_size")
        }

        backend.pcmBuffer.append(contentsOf: UnsafeBufferPointer(start: outBuf, count: Int(outSize)))
    }

    let toCopy = min(BUFFER_SIZE, backend.pcmBuffer.count)

    outBuffer.audioDataByteSize = toCopy

    backend.pcmBuffer.withUnsafeBytes { srcRaw in
        outBuffer.audioData.withUnsafeMutableBytes { dstRaw in
            let srcPtr = srcRaw.baseAddress!
            let dstPtr = dstRaw.baseAddress!
            memcpy(dstPtr, srcPtr, toCopy)
        }
    }

    if backend.pcmBuffer.count > toCopy {
        backend.pcmBuffer.replaceSubrange(0 ..< toCopy, with: [])
    } else {
        backend.pcmBuffer.removeAll()
    }
}

/* ****************************************
 *
 * ****************************************/
fileprivate func readMetadta(backend: Backend, tag: UnsafeMutablePointer<AVDictionaryEntry>?) {
    guard
        let tag = tag,
        let value = tag.pointee.value,
        let streamTitle = String(validatingUTF8: value)
    else {
        return
    }

    if backend.prevNowPlaying == streamTitle {
        return
    }

    backend.prevNowPlaying = streamTitle
    Task.detached { @MainActor in
        backend.frontend.nowPlaing = streamTitle
    }
}

/* ****************************************
 *
 * ****************************************/
typealias FFmpegInterruptCallback = @convention(c) (UnsafeMutableRawPointer?) -> Int32
let interruptCallback: FFmpegInterruptCallback = { opaque in
    guard let opaque else { return 0 }
    let backend = Unmanaged<Backend>.fromOpaque(opaque).takeUnretainedValue()

    return backend.shouldInterrupt.value ? 1 : 0
}

// MARK: - AudioQueue callback

fileprivate func fillAudioQueueBuffer(userData: UnsafeMutableRawPointer?, outAQ: AudioQueueRef, outBuffer: AudioQueueBufferRef) {
    guard let userData = userData else { return }
    let backend = Unmanaged<Backend>.fromOpaque(userData).takeUnretainedValue()

    // print("Buffers: \(backend.ringBuffer.readyNum())")

    guard let index = backend.ringBuffer.readIndex() else {
        let silent = Array(repeating: UInt8(0), count: Int(BUFFER_SIZE))
        let dest = outBuffer.pointee.mAudioData

        outBuffer.pointee.mAudioDataByteSize = UInt32(silent.count)
        memcpy(dest, silent, silent.count)
        AudioQueueEnqueueBuffer(outAQ, outBuffer, 0, nil)
        // backend.ringBuffer.debug("@@@ Buffer is empty")
        return
    }

    let src = backend.ringBuffer.buffers[index]
    let dest = outBuffer.pointee.mAudioData

    outBuffer.pointee.mAudioDataByteSize = UInt32(src.audioDataByteSize)
    memcpy(dest, src.audioData, src.audioDataByteSize)
    AudioQueueEnqueueBuffer(outAQ, outBuffer, 0, nil)
    backend.ringBuffer.incReadIndex()
}

// MARK: -  NSError

extension NSError {
    /* ****************************************
     *
     * ****************************************/
    convenience init(code: Int, message: String, debug: String) {
        self.init(
            domain: "FFPlayer",
            code: Int(code),
            userInfo: [
                NSLocalizedDescriptionKey: message,
                NSDebugDescriptionErrorKey: debug,
            ]
        )
    }

    /* ****************************************
     *
     * ****************************************/
    convenience init(code: FFPlayer.ErrorCode, message: String, debug: String) {
        self.init(code: Int(code.rawValue), message: message, debug: debug)
    }

    /* ****************************************
     *
     * ****************************************/
    convenience init(code: FFPlayer.ErrorCode, error: OSStatus, message: String, debug: String) {
        let desc = SecCopyErrorMessageString(error, nil) as String? ?? ""
        let dbg = "\(debug). error code = \(code.rawValue) : \(desc)"
        self.init(code: Int(code.rawValue), message: message, debug: dbg)
    }

    /* ****************************************
     *
     * ****************************************/
    convenience init(ffCode: Int32, message: String, debug: String) {
        var errorBuffer = [CChar](repeating: 0, count: 1024)
        av_make_error_string(&errorBuffer, 1024, ffCode)

        let ffmpegError = String(cString: errorBuffer)
        let dbg = "\(debug). error code = \(ffCode) : \(ffmpegError)"

        self.init(code: Int(ffCode), message: message, debug: dbg)
    }
}

// MARK: -  AtomicBool

fileprivate class AtomicBool {
    private var val: Bool = false
    private var mutex = pthread_mutex_t()

    init(val: Bool = false) {
        pthread_mutex_init(&mutex, nil)
        value = val
    }

    deinit {
        pthread_mutex_destroy(&mutex)
    }

    var value: Bool {
        get {
            pthread_mutex_lock(&mutex)
            let res = val
            pthread_mutex_unlock(&mutex)
            return res
        }
        set {
            pthread_mutex_lock(&mutex)
            val = newValue
            pthread_mutex_unlock(&mutex)
        }
    }
}

/* ****************************************
 *
 * ****************************************/
func printFFErrors() {
    func dump(_ code: Int32, _ name: String) {
        var errorBuffer = [CChar](repeating: 0, count: 1024)
        av_make_error_string(&errorBuffer, 1024, code)
        let ffError = String(cString: errorBuffer)

        print(String(format: "%-5d - %@ %@", code, name, ffError))
    }

    dump(-ETIMEDOUT, "ETIMEDOUT")
    dump(averror_bsf_not_found, "AVERROR_BSF_NOT_FOUND")
    dump(averror_bsf_not_found, "AVERROR_BSF_NOT_FOUND")
    dump(averror_bug, "AVERROR_BUG")
    dump(averror_buffer_too_small, "AVERROR_BUFFER_TOO_SMALL")
    dump(averror_decoder_not_found, "AVERROR_DECODER_NOT_FOUND")
    dump(averror_demuxer_not_found, "AVERROR_DEMUXER_NOT_FOUND")
    dump(averror_encoder_not_found, "AVERROR_ENCODER_NOT_FOUND")
    dump(averror_eof, "AVERROR_EOF")
    dump(averror_exit, "AVERROR_EXIT")
    dump(averror_external, "AVERROR_EXTERNAL")
    dump(averror_filter_not_found, "AVERROR_FILTER_NOT_FOUND")
    dump(averror_invaliddata, "AVERROR_INVALIDDATA")
    dump(averror_muxer_not_found, "AVERROR_MUXER_NOT_FOUND")
    dump(averror_option_not_found, "AVERROR_OPTION_NOT_FOUND")
    dump(averror_patchwelcome, "AVERROR_PATCHWELCOME")
    dump(averror_protocol_not_found, "AVERROR_PROTOCOL_NOT_FOUND")
    dump(averror_stream_not_found, "AVERROR_STREAM_NOT_FOUND")
    dump(averror_bug2, "AVERROR_BUG2")
    dump(averror_unknown, "AVERROR_UNKNOWN")
    dump(averror_experimental, "AVERROR_EXPERIMENTAL")
    dump(averror_input_changed, "AVERROR_INPUT_CHANGED")
    dump(averror_output_changed, "AVERROR_OUTPUT_CHANGED")
    dump(averror_http_bad_request, "AVERROR_HTTP_BAD_REQUEST")
    dump(averror_http_unauthorized, "AVERROR_HTTP_UNAUTHORIZED")
    dump(averror_http_forbidden, "AVERROR_HTTP_FORBIDDEN")
    dump(averror_http_not_found, "AVERROR_HTTP_NOT_FOUND")
    dump(averror_http_too_many_requests, "AVERROR_HTTP_TOO_MANY_REQUESTS")
    dump(averror_http_other_4xx, "AVERROR_HTTP_OTHER_4XX")
    dump(averror_http_server_error, "AVERROR_HTTP_SERVER_ERROR")
    dump(av_error_max_string_size, "AV_ERROR_MAX_STRING_SIZE")
}

/* ****************************************
 *
 * ****************************************/
fileprivate func hexDump(_ data: [UInt8], bytesPerLine: Int = 32) {
    for i in stride(from: 0, to: data.count, by: bytesPerLine) {
        let chunk = data[i ..< min(i + bytesPerLine, data.count)]
        let hex = chunk.map { String(format: "%02X", $0) }.joined(separator: " ")
        print(String(format: "%04X: %@", i, hex))
    }
}

/* ****************************************
 *
 * ****************************************/
fileprivate func hexDump(_ buffer: AudioQueueBufferRef, bytesPerLine: Int = 32) {
    let size = Int(buffer.pointee.mAudioDataByteSize)
    guard size > 0 else {
        print("(empty AudioQueue buffer)")
        return
    }

    let ptr = buffer.pointee.mAudioData.assumingMemoryBound(to: UInt8.self)

    for i in stride(from: 0, to: size, by: bytesPerLine) {
        let lineSize = min(bytesPerLine, size - i)
        var hexPart = ""

        for j in 0 ..< lineSize {
            let byte = ptr[i + j]
            hexPart += String(format: "%02X ", byte)
        }

        print(String(format: "%04X: %@", i, hexPart))
    }
}
