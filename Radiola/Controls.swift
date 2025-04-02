//
//  Controls.swift
//  Radiola
//
//  Created by Alex Sokolov on 10.07.2022.
//

import AppKit
import Cocoa

extension NSControl {
    func setFontWeight(_ weight: NSFont.Weight) {
        if let font = font {
            self.font = NSFont.systemFont(ofSize: font.pointSize, weight: weight)
        }
    }
}

// MARK: - NSWindow

public extension NSWindow {
    func show() {
        makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Workaround for window activation issues:  toggle focus away from the app and back.
        // https://ar.al/2018/09/17/workaround-for-unclickable-app-menu-bug-with-window.makekeyandorderfront-and-nsapp.activate-on-macos/
        if (NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first?.activate(options: []))!
        {
            let deadlineTime = DispatchTime.now() + .milliseconds(200)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    @IBAction func windowFloatOnTop(_ sender: Any) {
        if level == .floating {
            level = .normal
        } else {
            level = .floating
        }
    }
}

// MARK: - NSView

public extension NSView {
    /* ****************************************
     *
     * ****************************************/
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

    /* ****************************************
     *
     * ****************************************/
    func setBackgroundColor(_ color: NSColor) {
        wantsLayer = true
        layer?.backgroundColor = color.cgColor
    }

    /* ****************************************
     *
     * ****************************************/
    func addSubview(_ view: NSView?) {
        if let view = view {
            addSubview(view)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func findSubviews<T: NSView>(ofType type: T.Type) -> [T] {
        var result: [T] = []

        for subview in subviews {
            if let matchedView = subview as? T {
                result.append(matchedView)
            }
            result.append(contentsOf: subview.findSubviews(ofType: type))
        }

        return result
    }
}

// MARK: - NSImage

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

// MARK: - ScrollableSlider

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
    static func showWarning(message: String, informativeText: String = "") {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.alertStyle = .warning
        alert.runModal()
    }

    static func showInfo(message: String, informativeText: String = "") {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
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

// MARK: - ImageButton

class ImageButton: NSButton {
    init(image: NSImage? = nil) {
        super.init(frame: NSRect())
        bezelStyle = .shadowlessSquare
        isBordered = false
        setButtonType(.toggle)
        self.image = image
    }

    convenience init(systemSymbolName: String, accessibilityDescription: String) {
        self.init(image: NSImage(systemSymbolName: NSImage.Name(systemSymbolName), accessibilityDescription: accessibilityDescription))
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

// MARK: - IconView

class IconView: NSImageView {
    var onImage: NSImage? { didSet { updateImage() }}
    var offImage: NSImage? { didSet { updateImage() }}
    var state = NSControl.StateValue.off { didSet { updateImage() }}

    init() {
        super.init(frame: NSRect.zero)
    }

    convenience init(onImage: NSImage?, offImage: NSImage?) {
        self.init()
        self.onImage = onImage
        self.offImage = offImage
        updateImage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateImage() {
        switch state {
            case .off: image = offImage
            case .on: image = onImage
            default: image = offImage
        }
    }
}

// MARK: - Checkbox

class Checkbox: NSButton {
    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(frame: NSRect())

        setButtonType(.switch)
        bezelStyle = .regularSquare

        setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 250), for: .horizontal)
        setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 750), for: .vertical)

        setContentCompressionResistancePriority(NSLayoutConstraint.Priority(rawValue: 750), for: .horizontal)
        setContentCompressionResistancePriority(NSLayoutConstraint.Priority(rawValue: 750), for: .vertical)
    }

    /* ****************************************
     *
     * ****************************************/
    convenience init(title: String = "") {
        self.init()
        self.title = title
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - ContextMenu

class ContextMenu: NSMenu {
    private weak var view: NSTextField!

    /* ****************************************
     *
     * ****************************************/
    init(textField: NSTextField) {
        view = textField
        super.init(title: "")

        addItem(withTitle: "Copy", action: #selector(doCopy), keyEquivalent: "").target = self
    }

    /* ****************************************
     *
     * ****************************************/
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func doCopy() {
        print(view.stringValue)
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(view.stringValue, forType: .string)
    }
}

// MARK: - StationMenuButton

class StationMenuButton: NSButton {
    var station: Station?

    init() {
        super.init(frame: NSRect())
        bezelStyle = .shadowlessSquare
        isBordered = false
        image = NSImage(systemSymbolName: NSImage.Name("ellipsis"), accessibilityDescription: "Context menu")?.tint(color: .lightGray)
        target = self
        action = #selector(onClicked)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onClicked() {
        guard let station = station else { return }

        let p = NSPoint(x: frame.width / 2, y: frame.height / 2)
        let menu = NSMenu()

        menu.addItem(withTitle: NSLocalizedString("Copy station title to clipboard", comment: "Station action menu item"), action: #selector(copyTitleToClipboard), keyEquivalent: "").target = self
        menu.addItem(withTitle: NSLocalizedString("Copy station URL  to clipboard", comment: "Station action menu item"), action: #selector(copyUrlToClipboard), keyEquivalent: "").target = self

        menu.addItem(NSMenuItem.separator())

        for list in AppState.shared.localStations {
            if list.station(byURL: station.url) != nil {
                continue
            }

            menu.addItem(withTitle: String(format: NSLocalizedString("Add station to \"%@\"", comment: "Station action menu item. %@ is station list title."), list.title)) {
                list.add(station)
                list.trySave()
            }
        }
        menu.popUp(positioning: nil, at: p, in: self)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func copyTitleToClipboard() {
        guard let station = station else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(station.title, forType: .string)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func copyUrlToClipboard() {
        guard let station = station else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(station.url, forType: .string)
    }
}

// MARK: - StationGroupMenuButton

class StationGroupMenuButton: NSButton {
    var group: StationGroup?

    init() {
        super.init(frame: NSRect())
        bezelStyle = .shadowlessSquare
        isBordered = false
        image = NSImage(systemSymbolName: NSImage.Name("ellipsis"), accessibilityDescription: "Context menu")?.tint(color: .lightGray)
        target = self
        action = #selector(onClicked)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onClicked() {
        guard let group = group else { return }

        let p = NSPoint(x: frame.width / 2, y: frame.height / 2)
        let menu = NSMenu()

        menu.addItem(withTitle: "Copy group title to clipboard", action: #selector(copyTitleToClipboard), keyEquivalent: "").target = self

        menu.addItem(NSMenuItem.separator())

        for list in AppState.shared.localStations {
            if list.firstGroup(byID: group.id) != nil {
                continue
            }

            menu.addItem(withTitle: "Add group to \(list.title)") {
                list.add(group)
                list.trySave()
            }
        }
        menu.popUp(positioning: nil, at: p, in: self)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func copyTitleToClipboard() {
        guard let group = group else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(group.title, forType: .string)
    }
}

// MARK: - NSMenu

public extension NSMenu {
    func item(withIdentifier identifier: NSUserInterfaceItemIdentifier) -> NSMenuItem? {
        for item in items {
            if item.identifier == identifier {
                return item
            }

            if let submenu = item.submenu, let foundItem = submenu.item(withIdentifier: identifier) {
                return foundItem
            }
        }
        return nil
    }
}
