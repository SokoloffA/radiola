//
//  VolumeMenuItem.swift
//  Radiola
//
//  Created by Alex Sokolov on 03.12.2022.
//

import Cocoa

/* ****************************************
 *
 * ****************************************/
class VolumeMenuItem: NSMenuItem {
    /* ****************************************
     *
     * ****************************************/
    init(showMuteButton: Bool) {
        super.init(title: "", action: nil, keyEquivalent: "")
        view = VolumeView(showMuteButton: showMuteButton) // createView(showMuteButton: showMuteButton)
        view?.autoresizingMask = [.height, .width]
        view?.heightAnchor.constraint(equalToConstant: 30).isActive = true
        view?.widthAnchor.constraint(equalToConstant: 50).isActive = true
    }

    /* ****************************************
     *
     * ****************************************/
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
