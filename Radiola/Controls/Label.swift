//
//  Label.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 27.05.2026.
//

import Cocoa

// MARK: - Label

class Label: NSTextField {
    init() {
        super.init(frame: NSRect.zero)
        isEditable = false
        backgroundColor = NSColor.clear
        isBordered = false
        focusRingType = .none
        setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 250), for: .horizontal)
        setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 750), for: .vertical)
    }

    convenience init(text: String) {
        self.init()
        stringValue = text
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - SecondaryLabel

class SecondaryLabel: Label {
    override init() {
        super.init()
        font = NSFont.systemFont(ofSize: 12)
        textColor = .secondaryLabelColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
