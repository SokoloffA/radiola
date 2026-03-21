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

        backend.queue.sync {
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

// MARK: - Backend

class Backend {
    unowned let frontend: FFPlayer
    fileprivate let queue = DispatchQueue(label: "FFPlayerQueue")

    let ringBuffer = RingBuffer(buffersCount: NUM_RING_BUFFERS, bufferSize: BUFFER_SIZE)
    var decoder = FFDecoder()
    let macAudio: MacAudio

    fileprivate let userInterrupt = AtomicBool()
    fileprivate let shouldInterrupt = AtomicBool()
    var interruptCB: AVIOInterruptCB!

    private var ffmpegThread: Thread?

    /* ****************************************
     *
     * ****************************************/
    init(frontend: FFPlayer) {
        self.frontend = frontend
        macAudio = MacAudio(ringBuffer: ringBuffer, numBuffers: NUM_AUDIO_BUFFERS)

//        let opaque = Unmanaged.passUnretained(self).toOpaque()
//        interruptCB = AVIOInterruptCB(callback: interruptCallback, opaque: opaque)
    }

    /* ****************************************
     *
     * ****************************************/
    deinit {
        stop()
    }

    /* ****************************************
     *
     * ****************************************/
    func start(url: URL, volume: Float, deviceUID: String?) {
        do {
            setState(.connecting)

            var realURL: URL
            if PlayList.isPlayListURL(url) {
                let playList = PlayList()
                try playList.download(url: url)

                realURL = playList.urls[0]
            } else {
                realURL = url
            }

            debug("FFplayer load \(realURL)")
            ringBuffer.reset()

            debug(1)
            try decoder.load(url: realURL)
            debug(2)
            try fillRingBuffer()
            debug(3)

            try macAudio.start(format: decoder.format, deviceUID: deviceUID)
            try macAudio.setVolume(volume)

            // Start ffmpeg decoder thread
            let delay = macAudio.bufferDuration()

            ffmpegThread = Thread { [weak self, delay] in
                decode(backend: self!, delay: delay)
            }

            ffmpegThread?.name = "FFmpegDecoder"
            ffmpegThread?.qualityOfService = .userInitiated
            ffmpegThread?.start()

            try macAudio.startQueue()

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

        macAudio.stop()

        while let thread = ffmpegThread, thread.isExecuting {
            Thread.sleep(forTimeInterval: 0.01)
        }

        decoder.stop()

        Task.detached { @MainActor in
            if self.frontend.state != .stoped { self.frontend.state = .stoped }
            if self.frontend.nowPlaing != "" { self.frontend.nowPlaing = "" }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func fillRingBuffer() throws {
        // Preload audio
        for i in 0 ..< macAudio.numBuffers {
            try decoder.decodeBuffer(outBuffer: ringBuffer.buffers[i])
            ringBuffer.incWriteIndex()
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
        do {
            try macAudio.setVolume(volume)
        } catch {
            setError(error as NSError)
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

            try backend.decoder.decodeBuffer(outBuffer: backend.ringBuffer.buffers[index])
            backend.ringBuffer.incWriteIndex()
        }
    } catch {
        warning(error)
        backend.queue.async {
            backend.setError(error as NSError)
        }
    }
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
