//
//  PlayMenuItem.swift
//  Radiola
//
//  Created by Alex Sokolov on 14.04.2024.
//

import Cocoa

// MARK: - PlayItemView

class PlayItemView: NSView {
    private let playView = PlayView()
    private let favoriteButton = FavButton()
    private var topConstraint: NSLayoutConstraint!

    var playButton: NSButton { playView.playButton }

    var topMargin: Double {
        get { topConstraint.constant }
        set { topConstraint.constant = newValue }
    }

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(frame: .zero)
        createView()
        playView.target = self
        playView.action = #selector(onClick)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)

        refresh()
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /* ****************************************
     *
     * ****************************************/
    private func createView() {
        addSubview(playView)
        addSubview(favoriteButton)

        favoriteButton.image = NSImage(systemSymbolName: NSImage.Name("heart"), accessibilityDescription: "Mark current song as favorite")
        favoriteButton.alternateImage = NSImage(systemSymbolName: NSImage.Name("heart.fill"), accessibilityDescription: "Unmark current song as favorite")
        favoriteButton.target = self
        favoriteButton.action = #selector(markAsFavoriteSong)
        favoriteButton.toolTip = NSLocalizedString("Mark current song as favorite", comment: "Button tooltip")
        favoriteButton.setButtonType(.toggle)

        playView.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false

        playView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        topConstraint = playView.bottomAnchor.constraint(equalTo: bottomAnchor)
        topConstraint.isActive = true

        playView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true

        favoriteButton.heightAnchor.constraint(equalToConstant: 25.0).isActive = true
        favoriteButton.widthAnchor.constraint(equalToConstant: 25.0).isActive = true
        favoriteButton.centerYAnchor.constraint(equalTo: playView.songLabel.centerYAnchor, constant: 0).isActive = true
        favoriteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
    }

    /* ****************************************
     *
     * ****************************************/
//    override func mouseUp(with event: NSEvent) {
//        player.toggle()
//        onClick()
//    }
//
//    /* ****************************************
//     *
//     * ****************************************/
//    override func rightMouseUp(with event: NSEvent) {
//        player.toggle()
//        onClick()
//    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func refresh() {
        favoriteButton.isVisible = !player.songTitle.isEmpty
        favoriteButton.state = player.isFavoriteSong ? .on : .off
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func markAsFavoriteSong() {
        player.isFavoriteSong = !player.isFavoriteSong
        refresh()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func onClick() {
        window?.close()
    }
}

// MARK: - FavButton

fileprivate class FavButton: ImageButton {
    override func mouseUp(with event: NSEvent) {
        // Block the passing of mouse clicks to the parent even for the disabled state.
    }

    override func rightMouseUp(with event: NSEvent) {
        // Block the passing of mouse clicks to the parent even for the disabled state.
    }
}
