//
//  MediaKeysController.swift
//  Radiola
//
//  Created by Alex Sokolov on 22.07.2023.
//

import Cocoa

class MediaKeysController {
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
    public func handleEvent(_ event: NSEvent) {
        if !needHandleMediaKey() {
            return
        }

        let keyCode = ((event.data1 & 0xFFFF0000) >> 16)
        let keyFlags = (event.data1 & 0x0000FFFF)
        // Get the key state. 0xA is KeyDown, OxB is KeyUp
        let pressed = ((keyFlags & 0xFF00) >> 8) == 0xA
        let keyRepeat = (keyFlags & 0x1) != 0

        if pressed {
            switch Int32(keyCode) {
                case NX_KEYTYPE_PLAY: playKeyPressed(keyRepeat: keyRepeat)
                case NX_KEYTYPE_PREVIOUS: previousKeyPressed(keyRepeat: keyRepeat)
                case NX_KEYTYPE_NEXT: nextKeyPressed(keyRepeat: keyRepeat)
                default: break
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func playKeyPressed(keyRepeat: Bool) {
        if !keyRepeat {
            player.toggle()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func previousKeyPressed(keyRepeat: Bool) {
        if keyRepeat {
            return
        }

        switch settings.mediaPrevNextKeyAction {
            case .disable: return;
            case .switchStation: switchStation(offset: -1)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func nextKeyPressed(keyRepeat: Bool) {
        if keyRepeat {
            return
        }

        switch settings.mediaPrevNextKeyAction {
            case .disable: return;
            case .switchStation: switchStation(offset: 1)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func switchStation(offset: Int) {
        guard let curStation = player.station else { return }
        let favorites = stationsStore.favorites()
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
