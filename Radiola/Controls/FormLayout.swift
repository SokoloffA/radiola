//
//  FormLayout.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 23.06.2026.
//

import Cocoa

// MARK: - FormLayout

class FormLayout: NSGridView {
    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(frame: .zero)
        addColumn(with: [])
        addColumn(with: [])
        
        
        rowSpacing = 10
        columnSpacing = 12

        xPlacement = .leading
        rowAlignment = .firstBaseline

        column(at: 0).xPlacement = .trailing
        column(at: 1).xPlacement = .leading

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
    @discardableResult
    func addRow(rightView: NSView) -> NSGridRow {
        rightView.setContentCompressionResistancePriority(.required, for: .vertical)
        return addRow(with: [NSGridCell.emptyContentView, rightView])
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    func addRow(leftView: NSView, rightView: NSView) -> NSGridRow {
        leftView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        leftView.setContentCompressionResistancePriority(.required, for: .horizontal)
        leftView.setContentCompressionResistancePriority(.required, for: .vertical)
        rightView.setContentCompressionResistancePriority(.required, for: .vertical)
        return addRow(with: [leftView, rightView])
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    func addRow(title: String, rightView: NSView) -> NSGridRow {
        let label = Label(text: title)
        label.alignment = .right

        return addRow(leftView: label, rightView: rightView)
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    func addRow(leftView: NSView, rightViews: [NSView]) -> NSGridRow {
        let view = NSStackView(views: rightViews)
        return addRow(leftView: leftView, rightView: view)
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    func addRow(title: String, rightViews: [NSView]) -> NSGridRow {
        let label = Label(text: title)
        label.alignment = .right
        return addRow(leftView: label, rightViews: rightViews)
    }

    /* ****************************************
     *
     * ****************************************/
    func addSeparator() {
        let separator = Separator()
        let row = addRow(with: [separator, NSGridCell.emptyContentView])
        row.topPadding = 20
        let rowIndex = index(of: row)
        mergeCells(inHorizontalRange: NSRange(location: 0, length: 2),
                   verticalRange: NSRange(location: rowIndex, length: 1))
    }
}
