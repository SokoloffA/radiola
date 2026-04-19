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

extension AVSampleFormat: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
            case AV_SAMPLE_FMT_NONE: return "AV_SAMPLE_FMT_NONE"
            case AV_SAMPLE_FMT_U8: return "AV_SAMPLE_FMT_U8"
            case AV_SAMPLE_FMT_S16: return "AV_SAMPLE_FMT_S16"
            case AV_SAMPLE_FMT_S32: return "AV_SAMPLE_FMT_S32"
            case AV_SAMPLE_FMT_FLT: return "AV_SAMPLE_FMT_FLT"
            case AV_SAMPLE_FMT_DBL: return "AV_SAMPLE_FMT_DBL"
            case AV_SAMPLE_FMT_U8P: return "AV_SAMPLE_FMT_U8P"
            case AV_SAMPLE_FMT_S16P: return "AV_SAMPLE_FMT_S16P"
            case AV_SAMPLE_FMT_S32P: return "AV_SAMPLE_FMT_S32P"
            case AV_SAMPLE_FMT_FLTP: return "AV_SAMPLE_FMT_FLTP"
            case AV_SAMPLE_FMT_DBLP: return "AV_SAMPLE_FMT_DBLP"
            case AV_SAMPLE_FMT_S64: return "AV_SAMPLE_FMT_S64"
            case AV_SAMPLE_FMT_S64P: return "AV_SAMPLE_FMT_S64P"
            case AV_SAMPLE_FMT_NB: return "AV_SAMPLE_FMT_NB"
            default: return "AV_SAMPLE_FMT_UNKNOWN(\(rawValue))"
        }
    }
}

extension FFPlayer {
    enum ErrorCode: Int32 {
        case noError = 0
        case alocError_avframe
        case alocError_avpacket
        case alocError_avcodec
        case alocError_avformat
        case alocError_AudioQueue
        case alocError_AudioQueueBuffer
        case formatError
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
        case error(NSError)

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

extension FFPlayer {
    enum Event {
        case stateChanged(FFPlayer.State)
        case metadataReady(String?)
    }
}

// MARK: - FFPlayer

class FFPlayer {
    private let actor: FFPlayerActor
    private var playTask: Task<Void, Never>?
    private var stopTask: Task<Void, Never>?

    private let streamPair = AsyncStream<FFPlayer.Event>.makeStream()
    var events: AsyncStream<FFPlayer.Event> { streamPair.stream }

    /* ****************************************
     *
     * ****************************************/
    init() {
        actor = FFPlayerActor(continuation: streamPair.continuation)
    }

    /* ****************************************
     *
     * ****************************************/
    func start(url: URL, volume: Float, audioDevice: AudioDevice?) {
        let currentStopTask = stopTask
        playTask = Task {
            await currentStopTask?.value
            await actor.start(url: url, volume: volume, audioDevice: audioDevice)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func stop() {
        actor.interruptDecoder()
        playTask?.cancel()
        playTask = nil

        stopTask = Task {
            await actor.stop()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func setVolume(_ volume: Float) {
        Task {
            await actor.setVolume(volume)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    public func setOutputDevice(audioDevice: AudioDevice?) {
        Task {
            await actor.setOutputDevice(audioDevice: audioDevice)
        }
    }
}

// MARK: - FFPlayerActor

private actor FFPlayerActor {
    private let ringBuffer = RingBuffer(buffersCount: NUM_RING_BUFFERS, bufferSize: BUFFER_SIZE)
    private var decoder: FFDecoder
    private let macAudio: MacAudio

    private let userInterrupt = AtomicBool()
    private let decoderInterrupt = AtomicBool()

    typealias Event = FFPlayer.Event
    private let continuation: AsyncStream<FFPlayer.Event>.Continuation

    /* ****************************************
     *
     * ****************************************/
    init(continuation: AsyncStream<FFPlayer.Event>.Continuation) {
        self.continuation = continuation
        macAudio = MacAudio(ringBuffer: ringBuffer, numBuffers: NUM_AUDIO_BUFFERS)
        let decoder = FFDecoder(ringBuffer: ringBuffer, shouldInterrupt: decoderInterrupt)
        self.decoder = decoder

        decoder.onError = { [weak self] error in
            guard let self else { return }
            Task {
                await self.setError(error)
            }
        }

        decoder.metadataReady = { [weak self] metadata in
            guard let self else { return }
            Task {
                await self.emit(.metadataReady(metadata))
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func start(url: URL, volume: Float, audioDevice: AudioDevice?) {
        do {
            userInterrupt.value = false
            decoderInterrupt.value = false
            emit(.stateChanged(.connecting))

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

            try decoder.load(url: realURL)
            try fillRingBuffer()

            try macAudio.start(format: decoder.format, audioDevice: audioDevice)
            macAudio.fadeInVolume(to: volume)

            decoder.startDecodeThread()

            emit(.stateChanged(.playing))
        } catch {
            setError(error as NSError)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func stop() {
        macAudio.stop()
        decoder.stop()

        emit(.stateChanged(.stoped))
        emit(.metadataReady(nil))
    }

    /* ****************************************
     *
     * ****************************************/
    nonisolated func interruptDecoder() {
        userInterrupt.value = true
        decoderInterrupt.value = true
    }

    /* ****************************************
     * Preload audio
     * ****************************************/
    private func fillRingBuffer() throws {
        for i in 0 ..< macAudio.numBuffers {
            try decoder.decodeBuffer(outBuffer: ringBuffer.buffers[i])
            ringBuffer.incWriteIndex()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func setVolume(_ volume: Float) {
        macAudio.setVolume(volume)
    }

    /* ****************************************
     *
     * ****************************************/
    public func setOutputDevice(audioDevice: AudioDevice?) {
        macAudio.setOutputDevice(audioDevice: audioDevice)
    }

    /* ****************************************
     *
     * ****************************************/
    private func setError(_ error: NSError) {
        if userInterrupt.value || error.code == averror_exit {
            stop()
            emit(.stateChanged(.stoped))
            return
        }

        emit(.stateChanged(.error(error)))
        stop()
    }

    /* ****************************************
     *
     * ****************************************/
    private func emit(_ event: Event) {
        continuation.yield(event)
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
