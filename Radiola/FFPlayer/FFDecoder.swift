//
//  FFDecoder.swift
//  Radiola
//
//  Created by Alex Sokolov on 21.03.2026.
//

import AudioToolbox
import FFAudio
import Foundation

extension FFDecoder {
    struct Format {
        let sampleFormat: AVSampleFormat
        let channelsNum: Int32
        let sampleRate: Int32
        let isInterleaved: Bool

        init(sampleFormat: AVSampleFormat, channelsNum: Int32, sampleRate: Int32) {
            self.sampleFormat = sampleFormat
            self.channelsNum = channelsNum
            self.sampleRate = sampleRate

            switch sampleFormat {
                case AV_SAMPLE_FMT_FLT,
                     AV_SAMPLE_FMT_S16,
                     AV_SAMPLE_FMT_S32,
                     AV_SAMPLE_FMT_U8:
                    isInterleaved = true

                case AV_SAMPLE_FMT_FLTP,
                     AV_SAMPLE_FMT_S16P,
                     AV_SAMPLE_FMT_S32P,
                     AV_SAMPLE_FMT_U8P:
                    isInterleaved = false

                default:
                    isInterleaved = false
            }
        }

        var bytesPerSample: Int {
            switch sampleFormat {
                case AV_SAMPLE_FMT_FLT, AV_SAMPLE_FMT_FLTP: return 4
                case AV_SAMPLE_FMT_S32, AV_SAMPLE_FMT_S32P: return 4
                case AV_SAMPLE_FMT_S16, AV_SAMPLE_FMT_S16P: return 2
                case AV_SAMPLE_FMT_U8, AV_SAMPLE_FMT_U8P: return 1
                default: return 2
            }
        }
    }
}

class FFDecoder {
    private var ringBuffer: RingBuffer

    private var frame: UnsafeMutablePointer<AVFrame>!
    private var packet: UnsafeMutablePointer<AVPacket>!

    private var formatContext: UnsafeMutablePointer<AVFormatContext>!
    private var streamIndex: Int = -1
    private var codecContext: UnsafeMutablePointer<AVCodecContext>!
    private var swrContext: OpaquePointer!
    private var outLayout = AVChannelLayout()

    private let outFmt: AVSampleFormat = AV_SAMPLE_FMT_FLT
    private var outSampleRate: Int32 = 0
    private var outChannels: Int32 = 0

    private var pcmBuffer = [UInt8]()

    private var prevNowPlaying = ""

    private var interruptCB: AVIOInterruptCB!
    fileprivate let shouldInterrupt = AtomicBool()

    private var decodeThread: Thread?

    var format: Format {
        return Format(
            sampleFormat: outFmt,
            channelsNum: outChannels,
            sampleRate: outSampleRate
        )
    }

    var onError: ((NSError) -> Void)?
    var metadataReady: ((String?) -> Void)?

    /* ****************************************
     *
     * ****************************************/
    init(ringBuffer: RingBuffer) {
        self.ringBuffer = ringBuffer
        frame = av_frame_alloc()
        packet = av_packet_alloc()

        let opaque = Unmanaged.passUnretained(self).toOpaque()
        interruptCB = AVIOInterruptCB(callback: interruptCallback, opaque: opaque)
    }

    /* ****************************************
     *
     * ****************************************/
    deinit {
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
    func load(url: URL) throws {
        setupFFmpegLogging()

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

        // formatContext.pointee.interrupt_callback = interruptCB

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
    }

    /* ****************************************
     *
     * ****************************************/
    func stop() {
        shouldInterrupt.value = true

        while let thread = decodeThread, thread.isExecuting {
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
                debug("[FFmpeg] \(FFDecoder.ffmpegLogLevelToString(level)): \(message)")
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
    func decodeBuffer(outBuffer: RingBuffer.Buffer) throws {
        var timeoutCount = 0
        let maxTimeouts = 10

        var err: Int32 = 0
        let bufferSize = outBuffer.audioData.count

        while pcmBuffer.count < bufferSize {
            err = av_read_frame(formatContext, packet)
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
                av_packet_unref(packet)
            }
            readMetadta(tag: av_dict_get(formatContext.pointee.metadata, "StreamTitle", nil, 0))

            if packet.pointee.stream_index != streamIndex {
                continue
            }

            err = avcodec_send_packet(codecContext, packet)
            if err < 0 {
                throw NSError(ffCode: err, message: internalErrorDescription, debug: "Error calling avcodec_send_packet")
            }

            err = avcodec_receive_frame(codecContext, frame)
            if err == -EAGAIN {
                continue
            } else if err < 0 {
                throw NSError(ffCode: err, message: internalErrorDescription, debug: "Error calling avcodec_receive_frame")
            }

            let dstNbSamples = av_rescale_rnd(
                swr_get_delay(swrContext, Int64(codecContext.pointee.sample_rate)) + Int64(frame.pointee.nb_samples),
                Int64(outSampleRate),
                Int64(codecContext.pointee.sample_rate),
                AV_ROUND_UP)

            var outLinesize: Int32 = 0
            var outBuf: UnsafeMutablePointer<UInt8>?
            err = av_samples_alloc(&outBuf, &outLinesize, outChannels, Int32(dstNbSamples), outFmt, 0)
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

            let srcData = withUnsafePointer(to: &frame.pointee.data) {
                UnsafeRawPointer($0).assumingMemoryBound(to: UnsafePointer<UInt8>?.self)
            }

            let samplesConverted = swr_convert(swrContext,
                                               outBufPointer,
                                               Int32(dstNbSamples),
                                               srcData,
                                               frame.pointee.nb_samples)

            if samplesConverted < 0 {
                throw NSError(ffCode: samplesConverted, message: internalErrorDescription, debug: "Error calling swr_convert")
            }

            let outSize = av_samples_get_buffer_size(nil, outChannels, samplesConverted, outFmt, 1)
            if outSize < 0 {
                throw NSError(ffCode: outSize, message: internalErrorDescription, debug: "Error calling av_samples_get_buffer_size")
            }

            pcmBuffer.append(contentsOf: UnsafeBufferPointer(start: outBuf, count: Int(outSize)))
        }

        let toCopy = min(bufferSize, pcmBuffer.count)

        outBuffer.audioDataByteSize = toCopy

        pcmBuffer.withUnsafeBytes { srcRaw in
            outBuffer.audioData.withUnsafeMutableBytes { dstRaw in
                let srcPtr = srcRaw.baseAddress!
                let dstPtr = dstRaw.baseAddress!
                memcpy(dstPtr, srcPtr, toCopy)
            }
        }

        if pcmBuffer.count > toCopy {
            pcmBuffer.replaceSubrange(0 ..< toCopy, with: [])
        } else {
            pcmBuffer.removeAll()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func readMetadta(tag: UnsafeMutablePointer<AVDictionaryEntry>?) {
        guard
            let tag = tag,
            let value = tag.pointee.value,
            let streamTitle = String(validatingUTF8: value)
        else {
            return
        }

        if prevNowPlaying == streamTitle {
            return
        }

        prevNowPlaying = streamTitle
        metadataReady?(streamTitle)
    }

    /* ****************************************
     *
     * ****************************************/
    func startDecodeThread() {
        shouldInterrupt.value = false
        let delay = bufferDuration()
        decodeThread = Thread { [weak self, delay] in
            do {
                while true {
                    guard let self = self else { return }

                    if self.shouldInterrupt.value {
                        return
                    }

                    guard let index = ringBuffer.writeIndex() else {
                        Thread.sleep(forTimeInterval: delay)
                        continue
                    }

                    try decodeBuffer(outBuffer: ringBuffer.buffers[index])
                    ringBuffer.incWriteIndex()
                }
            } catch {
                guard let self = self else { return }
                if self.shouldInterrupt.value {
                    return
                }

                warning(error)
                self.onError?(error as NSError)
            }
        }

        decodeThread?.name = "FFmpegDecoder"
        decodeThread?.qualityOfService = .userInitiated
        decodeThread?.start()
    }

    /* ****************************************
     *
     * ****************************************/
    private func bufferDuration() -> TimeInterval {
        var bytesPerSample: Int
        switch outFmt {
            case AV_SAMPLE_FMT_U8, AV_SAMPLE_FMT_U8P:
                bytesPerSample = 1
            case AV_SAMPLE_FMT_S16, AV_SAMPLE_FMT_S16P:
                bytesPerSample = 2
            case AV_SAMPLE_FMT_S32, AV_SAMPLE_FMT_S32P,
                 AV_SAMPLE_FMT_FLT, AV_SAMPLE_FMT_FLTP:
                bytesPerSample = 4
            case AV_SAMPLE_FMT_DBL, AV_SAMPLE_FMT_DBLP:
                bytesPerSample = 8
            default:
                return 44100 * 2
        }

        let bytesPerFrame = bytesPerSample * Int(outChannels)
        let frames = Double(ringBuffer.bufferSize) / Double(bytesPerFrame)
        return frames / Double(outSampleRate)
    }
}

/* ****************************************
 *
 * ****************************************/
typealias FFmpegInterruptCallback = @convention(c) (UnsafeMutableRawPointer?) -> Int32
let interruptCallback: FFmpegInterruptCallback = { opaque in
    guard let opaque else { return 0 }
    let decoder = Unmanaged<FFDecoder>.fromOpaque(opaque).takeUnretainedValue()

    return decoder.shouldInterrupt.value ? 1 : 0
}
