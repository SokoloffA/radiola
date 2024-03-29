//
//  Controls.swift
//  Radiola
//
//  Created by Alex Sokolov on 10.07.2022.
//

import Cocoa

public extension NSView {
    func load(fromNIBNamed nibName: String) -> NSView? {
        var nibObjects: NSArray?
        let nibName = NSNib.Name(stringLiteral: nibName)

        if Bundle.main.loadNibNamed(nibName, owner: self, topLevelObjects: &nibObjects) {
            guard let nibObjects = nibObjects else { return nil }

            let viewObjects = nibObjects.filter { $0 is NSView }

            if viewObjects.count > 0 {
                guard let view = viewObjects[0] as? NSView else { return nil }
                addSubview(view)

                view.translatesAutoresizingMaskIntoConstraints = false
                view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                view.topAnchor.constraint(equalTo: topAnchor).isActive = true
                view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

                return view
            }
        }

        return nil
    }
}

public extension NSImage {
    func tint(color: NSColor) -> NSImage {
        if isTemplate == false {
            return self
        }

        let image = copy() as! NSImage
        image.lockFocus()

        color.set()

        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceIn)

        image.unlockFocus()
        image.isTemplate = false

        return image
    }

    func writePNG(toURL url: URL) {
        guard let data = tiffRepresentation,
              let rep = NSBitmapImageRep(data: data),
              let imgData = rep.representation(using: .png, properties: [.compressionFactor: NSNumber(floatLiteral: 1.0)]) else {
            Swift.print("\(self) Error Function '\(#function)' Line: \(#line) No tiff rep found for image writing to \(url)")
            return
        }

        do {
            try imgData.write(to: url)
        } catch let error {
            Swift.print("\(self) Error Function '\(#function)' Line: \(#line) \(error.localizedDescription)")
        }
    }
}

class ScrollableSlider: NSSlider {
    override func scrollWheel(with event: NSEvent) {
        guard isEnabled else { return }

        let range = Float(maxValue - minValue)
        var delta = Float(0)

        // Allow horizontal scrolling on horizontal and circular sliders
        if _isVertical && sliderType == .linear {
            delta = Float(event.deltaY)
        } else if userInterfaceLayoutDirection == .rightToLeft {
            delta = Float(event.deltaY + event.deltaX)
        } else {
            delta = Float(event.deltaY - event.deltaX)
        }

        // Account for natural scrolling
        if event.isDirectionInvertedFromDevice {
            delta *= -1
        }

        let increment = range * delta / 100
        var value = floatValue + increment

        // Wrap around if slider is circular
        if sliderType == .circular {
            let minValue = Float(self.minValue)
            let maxValue = Float(self.maxValue)

            if value < minValue {
                value = maxValue - abs(increment)
            } else if value > maxValue {
                value = minValue + abs(increment)
            }
        }

        floatValue = value
        sendAction(action, to: target)
    }

    private var _isVertical: Bool {
        if #available(macOS 10.12, *) {
            return self.isVertical
        } else {
            // isVertical is an NSInteger in versions before 10.12
            return value(forKey: "isVertical") as! NSInteger == 1
        }
    }
}

public extension NSAlert {
    static func showWarning(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    static func showInfo(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.runModal()
    }
}

// MARK: - Separator

class Separator: NSBox {
    init() {
        super.init(frame: NSRect())
        boxType = .separator
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func alignBottom(of supreView: NSView) {
        leadingAnchor.constraint(equalTo: supreView.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: supreView.trailingAnchor).isActive = true
        bottomAnchor.constraint(equalTo: supreView.bottomAnchor).isActive = true
    }
}

// MARK: - TextField

class TextField: NSTextField {
    init() {
        super.init(frame: NSRect())
        isBordered = false
        drawsBackground = false
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - TextField

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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - ImageButton

class ImageButton: NSButton {
    init() {
        super.init(frame: NSRect())
        bezelStyle = .shadowlessSquare
        isBordered = false
        setButtonType(.momentaryPushIn)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NSControl {
    func setFontWeight(_ weight: NSFont.Weight) {
        if let font = font {
            self.font = NSFont.systemFont(ofSize: font.pointSize, weight: .bold)
        }
    }
}
