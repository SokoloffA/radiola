//
//  MediaKeysController.swift
//  Radiola
//
//  Created by Alex Sokolov on 22.07.2023.
//

import Cocoa
import MediaPlayer

// MARK: - MediaKeysController

class MediaKeysController: NSObject {
    /* ****************************************
     *
     * ****************************************/
    override init() {
        super.init()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerStatusChanged),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerMetadataChanged),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)

        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.playCommand.addTarget(self, action: #selector(play))
        remoteCommandCenter.pauseCommand.addTarget(self, action: #selector(stop))
        remoteCommandCenter.stopCommand.addTarget(self, action: #selector(stop))
        remoteCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(toggle))
        remoteCommandCenter.nextTrackCommand.addTarget(self, action: #selector(next))
        remoteCommandCenter.previousTrackCommand.addTarget(self, action: #selector(previous))

        playerStatusChanged()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func playerStatusChanged() {
        let playbackState: MPNowPlayingPlaybackState = player.isPlaying ? .playing : .paused
        if MPNowPlayingInfoCenter.default().playbackState != playbackState {
            debug("[NowPlayingInfo] Set playbackState to \(player.isPlaying ? "playing" : "paused")")
            MPNowPlayingInfoCenter.default().playbackState = playbackState
        }

        updateNowPlayingInfo()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func playerMetadataChanged() {
        updateNowPlayingInfo()
    }

    /* ****************************************
     * MediaRemote clients (Control Center, VoiceInk, etc.) treat an entry
     * without a title as not playing and won't resume it, so the station
     * name is used as the title when the stream has no song title.
     * ****************************************/
    private func updateNowPlayingInfo() {
        guard let station = player.station else { return }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: station.title,
            MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyIsLiveStream: true,
        ]

        if !player.songTitle.isEmpty {
            info[MPMediaItemPropertyTitle] = player.songTitle
            info[MPMediaItemPropertyArtist] = station.title
        }

        if let current = MPNowPlayingInfoCenter.default().nowPlayingInfo, NSDictionary(dictionary: current).isEqual(to: info) {
            return
        }

        debug("[NowPlayingInfo] Update playing info to \(info)")
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /* ****************************************
     *
     * ****************************************/
    private func needHandleMediaKey() -> Bool {
        switch settings.mediaKeysHandle {
            case .disable: return false
            case .enable: return true
            case .mainWindowActive: return StationsWindow.isActie()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func play(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if needHandleMediaKey() {
            player.play()
        }
        return .success
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func stop(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if needHandleMediaKey() {
            player.stop()
        }
        return .success
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func toggle(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if needHandleMediaKey() {
            player.toggle()
        }
        return .success
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func previous(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if needHandleMediaKey() && settings.mediaPrevNextKeyAction == .switchStation {
            switchStation(offset: -1)
        }
        return .success
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func next(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if needHandleMediaKey() && settings.mediaPrevNextKeyAction == .switchStation {
            switchStation(offset: 1)
        }
        return .success
    }

    /* ****************************************
     *
     * ****************************************/
    private func switchStation(offset: Int) {
        guard let curStation = player.station else { return }
        let favorites = AppState.shared.favoritesStations()
        if favorites.count <= 1 { return }

        var newIndex = 0
        if let curIndex = favorites.firstIndex(where: { $0.url == curStation.url }) {
            newIndex = (curIndex + offset) % favorites.count
            if newIndex < 0 {
                newIndex += favorites.count
            }
        }

        player.station = favorites[newIndex]
        player.play()
    }
}
