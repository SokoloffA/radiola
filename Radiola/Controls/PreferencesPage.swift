//
//  PreferencesPage.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 24.05.2026.
//

import Cocoa

class PreferencesPage: NSViewController {
    private let gridView = NSGridView(numberOfColumns: 2, rows: 0)

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(nibName: nil, bundle: nil)

        view = NSView()
        view.addSubview(gridView)

        gridView.translatesAutoresizingMaskIntoConstraints = false

        gridView.rowSpacing = 8
        gridView.columnSpacing = 12

        gridView.xPlacement = .leading
        gridView.yPlacement = .center

        gridView.column(at: 0).xPlacement = .trailing
        gridView.column(at: 1).xPlacement = .leading

        NSLayoutConstraint.activate([
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            gridView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32),
        ])

        gridView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        gridView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        gridView.setContentCompressionResistancePriority(.required, for: .vertical)
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
        return gridView.addRow(with: [NSGridCell.emptyContentView, rightView])
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
        return gridView.addRow(with: [leftView, rightView])
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
        let row = gridView.addRow(with: [separator, NSGridCell.emptyContentView])
        row.topPadding = 20
        let rowIndex = gridView.index(of: row)
        gridView.mergeCells(inHorizontalRange: NSRange(location: 0, length: 2),
                            verticalRange: NSRange(location: rowIndex, length: 1))
    }
}
