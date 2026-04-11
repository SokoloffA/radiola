//
//  AirPlayButton.swift
//  Radiola
//
//  Created by Alex Sokolov on 07.03.2026.
//

import AppKit
import AVKit

final class AirPlayButton: NSView {

    private let routePicker = AVRoutePickerView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        routePicker.translatesAutoresizingMaskIntoConstraints = false
        addSubview(routePicker)

        routePicker.isRoutePickerButtonBordered = false
        NSLayoutConstraint.activate([
            routePicker.leadingAnchor.constraint(equalTo: leadingAnchor),
            routePicker.trailingAnchor.constraint(equalTo: trailingAnchor),
            routePicker.topAnchor.constraint(equalTo: topAnchor),
            routePicker.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
