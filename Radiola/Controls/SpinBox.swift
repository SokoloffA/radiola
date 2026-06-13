//
//  SpinBox.swift
//  Radiola
//
//  Created by Alex Sokolov on 13.04.2025.
//

import Cocoa

class SpinBox: NSTextField {
    private let stepper = NSStepper()

    override var objectValue: Any? {
        get { NSNumber(value: stepper.integerValue) }
        set { stepper.objectValue = newValue; refreshEdit() }
    }

    override var integerValue: Int {
        get { return stepper.integerValue }
        set { stepper.integerValue = newValue; refreshEdit() }
    }

    override var intValue: Int32 {
        get { return Int32(integerValue) }
        set { integerValue = Int(newValue) }
    }

    var minValue: Int {
        get { Int(stepper.minValue) }
        set { stepper.minValue = Double(newValue); refreshEdit() }
    }

    var maxValue: Int {
        get { Int(stepper.maxValue) }
        set { stepper.maxValue = Double(newValue); refreshEdit() }
    }

    open var increment: Int {
        get { Int(stepper.increment) }
        set { stepper.increment = Double(newValue); refreshEdit() }
    }

    var valueWraps: Bool {
        get { stepper.valueWraps }
        set { stepper.valueWraps = newValue; refreshEdit() }
    }

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(frame: .zero)
        let cell = SpinBoxCell(textCell: "")
        cell.isEditable = true
        cell.isScrollable = true
        cell.isBordered = true
        cell.isBezeled = true
        cell.rightMargin = 25
        self.cell = cell

        addSubview(stepper)
        stepper.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stepper.heightAnchor.constraint(equalTo: heightAnchor, constant: -8),
            stepper.centerYAnchor.constraint(equalTo: centerYAnchor),
            stepper.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        alignment = .right

        stepper.refusesFirstResponder = true
        stepper.valueWraps = false
        stepper.target = self
        stepper.action = #selector(stepperValueChanged(_:))

        refreshEdit()
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
    func validate(string: String) -> Bool {
        guard string.allSatisfy({ $0.isNumber }) else { return false }

        if let value = Int(string), value > maxValue {
            return false
        }

        return true
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func stepperValueChanged(_ sender: NSStepper) {
        if window?.firstResponder != currentEditor() {
            window?.makeFirstResponder(self)
        }

        refreshEdit()
        sendAction(action, to: target)
    }

    /* ****************************************
     *
     * ****************************************/
    private func refreshEdit() {
        super.integerValue = stepper.integerValue
    }

    /* ****************************************
     *
     * ****************************************/
    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        stepper.integerValue = super.integerValue

        currentEditor()?.textColor = (super.integerValue < minValue) ? .systemRed : textColor

        sendAction(action, to: target)
    }

    /* ****************************************
     *
     * ****************************************/
    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        super.integerValue = stepper.integerValue
    }

    /* ****************************************
     *
     * ****************************************/
    override func resetCursorRects() {
        super.resetCursorRects()
        let stepperBounds = stepper.frame
        addCursorRect(stepperBounds, cursor: .arrow)
    }
}

// MARK: - SpinBoxCell

fileprivate class SpinBoxCell: NSTextFieldCell {
    var rightMargin: CGFloat = 0
    private lazy var customFieldEditor: SpinBoxEditor = {
        let res = SpinBoxEditor()
        res.isFieldEditor = true
        return res
    }()

    /* ****************************************
     *
     * ****************************************/
    override func fieldEditor(for controlView: NSView) -> NSTextView? {
        return customFieldEditor
    }

    /* ****************************************
     *
     * ****************************************/
    override func titleRect(forBounds rect: NSRect) -> NSRect {
        var r = super.titleRect(forBounds: rect)
        r.size.width -= rightMargin
        return r
    }

    /* ****************************************
     *
     * ****************************************/
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        var r = super.drawingRect(forBounds: rect)
        r.size.width -= rightMargin
        return r
    }
}

// MARK: - SpinBoxEditor

fileprivate class SpinBoxEditor: NSTextView, NSTextViewDelegate {
    /* ****************************************
     *
     * ****************************************/
    private var spinBox: SpinBox? {
        return delegate as? SpinBox
    }

    /* ****************************************
     *
     * ****************************************/
    override func shouldChangeText(in range: NSRange, replacementString: String?) -> Bool {
        guard let chars = replacementString else { return true }

        if chars.isEmpty { return true }

        let newText = (string as NSString)
            .replacingCharacters(in: range, with: chars)

        return spinBox?.validate(string: newText) ?? true
    }
}
