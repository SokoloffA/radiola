//
//  Buttons.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 27.05.2026.
//

import Cocoa

// MARK: - ImageButton

class ImageButton: NSButton {
    init(image: NSImage? = nil) {
        super.init(frame: NSRect())
        bezelStyle = .shadowlessSquare
        isBordered = false
        self.image = image
    }

    convenience init(systemSymbolName: String, accessibilityDescription: String) {
        self.init(image: NSImage(systemSymbolName: NSImage.Name(systemSymbolName), accessibilityDescription: accessibilityDescription))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - ToggleButton

class ToggleButton: ImageButton {
    init(onImage: NSImage?, offImage: NSImage?) {
        super.init(image: onImage)
        alternateImage = offImage
        setButtonType(.toggle)
    }

    convenience init(onSystemSymbolName: String,
                     onAccessibilityDescription: String,
                     offSystemSymbolName: String,
                     offAccessibilityDescription: String) {
        self.init(
            onImage: NSImage(systemSymbolName: NSImage.Name(onSystemSymbolName), accessibilityDescription: onAccessibilityDescription),
            offImage: NSImage(systemSymbolName: NSImage.Name(offSystemSymbolName), accessibilityDescription: offAccessibilityDescription))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - MenuButton

class MenuButton: NSButton {
    init() {
        super.init(frame: NSRect())
        bezelStyle = .shadowlessSquare
        isBordered = false
        image = NSImage(systemSymbolName: NSImage.Name("ellipsis"), accessibilityDescription: "Context menu")?.tint(color: .lightGray)
//        image = NSImage(systemSymbolName: NSImage.Name("ellipsis.circle"), accessibilityDescription: "Context menu")?.tint(color: .lightGray)
        menu = NSMenu()
        target = self
        action = #selector(onClicked)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onClicked() {
        let p = NSPoint(x: frame.width / 2, y: frame.height / 2)
        menu!.popUp(positioning: nil, at: p, in: self)
    }
}

// MARK: - MenuButton

class SpinnerImageButton: ImageButton {
    private let spinner: NSProgressIndicator = {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.controlSize = .small
        indicator.isDisplayedWhenStopped = false
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.wantsLayer = true
        indicator.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        return indicator
    }()

    private var spinnerIsActive = false
    private var _isEnabled: Bool = true
    override var isEnabled: Bool {
        get { return _isEnabled }
        set {
            _isEnabled = newValue
            super.isEnabled = newValue && !spinnerIsActive
        }
    }

    /* ****************************************
     *
     * ****************************************/
    override init(image: NSImage? = nil) {
        super.init(image: image)
        isEnabled = super.isEnabled
        initSpinner()
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isEnabled = super.isEnabled
        initSpinner()
    }

    /* ****************************************
     *
     * ****************************************/
    private func initSpinner() {
        addSubview(spinner)

        NSLayoutConstraint.activate([
            spinner.leadingAnchor.constraint(equalTo: leadingAnchor),
            spinner.trailingAnchor.constraint(equalTo: trailingAnchor),
            spinner.topAnchor.constraint(equalTo: topAnchor),
            spinner.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        spinner.isHidden = true
    }

    /* ****************************************
     *
     * ****************************************/
    @MainActor
    func setAsLoading(_ isLoading: Bool) {
        if isLoading {
            spinnerIsActive = true
            imagePosition = .noImage
            super.isEnabled = false
            spinner.startAnimation(nil)
            spinner.isHidden = false
        } else {
            spinnerIsActive = false
            imagePosition = .imageOnly
            spinner.stopAnimation(nil)
            super.isEnabled = isEnabled
            spinner.isHidden = true
        }
    }
}
