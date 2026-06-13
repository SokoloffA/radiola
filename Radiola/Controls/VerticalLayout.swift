//
//  VerticalLayout.swift
//  Radiola
//
//  Created by Alex Sokolov on 12.06.2026.
//

import Cocoa

// MARK: - WeakNSView

fileprivate class WeakNSView {
    weak var value: NSView?

    init(_ value: NSView) {
        self.value = value
    }
}

// MARK: - VerticalLayout

class VerticalLayout: NSView {
    private var items: [WeakNSView] = []
    private var layoutConstraints: [NSLayoutConstraint] = []

    /* ****************************************
     *
     * ****************************************/
    var arrangedSubviews: [NSView] {
        items = items.filter { $0.value != nil }
        return items.compactMap { $0.value }
    }

    /* ****************************************
     *
     * ****************************************/
    var edgeInsets: NSEdgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet {
            rebuildLayout()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(frame: .zero)
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
    private func lastView() -> NSView? {
        return items.last(where: { $0.value != nil })?.value
    }

    /* ****************************************
     *
     * ****************************************/
    func addArrangedSubview(_ view: NSView) {
        insertArrangedSubview(view, at: items.count)
    }

    /* ****************************************
     *
     * ****************************************/
    func insertArrangedSubview(_ view: NSView, at index: Int) {
        if view.superview != self {
            addSubview(view)
        }
        view.translatesAutoresizingMaskIntoConstraints = false

        let safeIndex = min(max(0, index), items.count)
        items.insert(WeakNSView(view), at: safeIndex)

        rebuildLayout()
    }

    /* ****************************************
     *
     * ****************************************/
    private func rebuildLayout() {
        NSLayoutConstraint.deactivate(layoutConstraints)
        layoutConstraints.removeAll()

        let activeViews = arrangedSubviews
        guard !activeViews.isEmpty else { return }

        for i in 0 ..< activeViews.count {
            let current = activeViews[i]

            layoutConstraints.append(current.leadingAnchor.constraint(equalTo: leadingAnchor, constant: edgeInsets.left))
            layoutConstraints.append(current.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -edgeInsets.right))

            if i == 0 {
                layoutConstraints.append(current.topAnchor.constraint(equalTo: topAnchor, constant: edgeInsets.top))
            } else {
                let previous = activeViews[i - 1]
                layoutConstraints.append(current.topAnchor.constraint(equalTo: previous.bottomAnchor))
            }

            if i == activeViews.count - 1 {
                layoutConstraints.append(current.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -edgeInsets.bottom))
            }
        }

        NSLayoutConstraint.activate(layoutConstraints)
    }
}
