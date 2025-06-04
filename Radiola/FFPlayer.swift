//
//  FFPlayer.swift
//  Radiola
//
//  Created by Alex Sokolov on 01.06.2025.
//

import FFAudioPlayer
import Foundation

fileprivate actor Backend {
    unowned let frontend: FFPlayer
    private let handle: OpaquePointer

    /* ****************************************
     *
     * ****************************************/
    init(frontend: FFPlayer) {
        self.frontend = frontend
        handle = ffplayer_create()
    }

    /* ****************************************
     *
     * ****************************************/
    deinit {
        ffplayer_free(handle)
    }

    /* ****************************************
     *
     * ****************************************/
    func start(url: URL, volume: Float, deviceUID: String?) async {
        let opaqueSelf = Unmanaged.passUnretained(self).toOpaque()

        ffplayer_set_state_callback(handle, opaqueSelf) { userData, state in
            guard let userData = userData else { return }
            let backend = Unmanaged<Backend>.fromOpaque(userData).takeUnretainedValue()
            Task { await backend.updateState(state) }
        }

        ffplayer_set_now_plaing_callback(handle, opaqueSelf) { userData, nowPlaing in
            guard let userData = userData else { return }
            let backend = Unmanaged<Backend>.fromOpaque(userData).takeUnretainedValue()
            Task { await backend.updateNowPlaing(String(cString: nowPlaing)) }
        }

        if ffplayer_load(handle, url.absoluteString) != 0 {
            return
        }

        await setVolume(volume: volume)
        ffplayer_start_queue(handle, deviceUID)
    }

    /* ****************************************
     *
     * ****************************************/
    private func updateState(_ state: FFPlayerState) async {
        var errCode = 0
        var errStr = ""
        if state == FFPlayer_Error {
            errCode = Int(ffplayer_get_error(handle))
            errStr = String(cString: ffplayer_get_error_string(handle))
        }

        let errorCode = errCode
        let errorString = errStr

        await MainActor.run {
            switch state {
                case FFPlayer_Stoped:
                    self.frontend.state = .stoped

                case FFPlayer_Loading:
                    self.frontend.state = .loading

                case FFPlayer_Playing:
                    self.frontend.state = .playing

                case FFPlayer_Error:
                    self.frontend.errorCode = errorCode
                    self.frontend.errorString = errorString
                    self.frontend.state = .error

                default: break
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func updateNowPlaing(_ nowPlaing: String?) async {
        await MainActor.run {
            self.frontend.nowPlaing = nowPlaing
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func setVolume(volume: Float) async {
        ffplayer_set_volume(handle, volume)
    }
}

extension FFPlayer {
    enum State {
        case stoped
        case loading
        case playing
        case error

        var description: String {
            switch self {
                case .stoped: return "stoped"
                case .loading: return "loading"
                case .playing: return "playing"
                case .error: return "error"
            }
        }
    }
}

public class FFPlayer: ObservableObject {
    private var backend: Backend?

    @Published fileprivate(set) var state = State.stoped
    @Published fileprivate(set) var nowPlaing: String?
    fileprivate var errorCode = 0
    fileprivate var errorString = ""

    var volume: Float = 1.0 {
        didSet { updateVolume() }
    }

    var isMuted: Bool = false {
        didSet { updateVolume() }
    }

    var audioOutputDeviceUniqueID: String?

    var isPlaing: Bool { state == .playing }

    var error: NSError? { getError() }

    /* ****************************************
     *
     * ****************************************/
    func play(url: URL) {
        let vol = isMuted ? 0.0 : volume
        backend = Backend(frontend: self)
        Task {
            await backend!.start(url: url, volume: vol, deviceUID: audioOutputDeviceUniqueID)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func stop() {
        nowPlaing = ""
        state = .stoped
        backend = nil
    }

    /* ****************************************
     *
     * ****************************************/
    private func updateVolume() {
        let vol = isMuted ? 0.0 : volume
        if let backend = backend {
            Task {
                await backend.setVolume(volume: vol)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func getError() -> NSError? {
        if errorCode == NoError {
            return nil
        }

        return NSError(domain: "FFPlayerErrorDomain", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorString])
    }
}
