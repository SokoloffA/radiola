//
//  AirPlayButton.swift
//  Radiola
//
//  Created by Alex Sokolov on 07.03.2026.
//

import AppKit
import AVKit

final class AirPlayButton: AVRoutePickerView {
    private let routeDetector = AVRouteDetector()

    /* ****************************************
     *
     * ****************************************/
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    /* ****************************************
     *
     * ****************************************/
    deinit {
        routeDetector.isRouteDetectionEnabled = false
    }

    /* ****************************************
     *
     * ****************************************/
    private func setup() {
        isRoutePickerButtonBordered = false
        routeDetector.isRouteDetectionEnabled = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateVisibility),
            name: .AVRouteDetectorMultipleRoutesDetectedDidChange,
            object: routeDetector
        )

        updateVisibility()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func updateVisibility() {
        isHidden = !routeDetector.multipleRoutesDetected
    }
}
