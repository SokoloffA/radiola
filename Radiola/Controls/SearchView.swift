//
//  SearchView.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.12.2023.
//

import SwiftUI

// MARK: - SearchView

struct SearchView: NSViewRepresentable {
    var placeholder: String
    var text: Binding<String>
    var action: (() -> Void)?

    /* ****************************************
     *
     * ****************************************/
    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField(frame: .zero)
        searchField.placeholderString = placeholder

        searchField.delegate = context.coordinator
        searchField.target = context.coordinator
        searchField.action = #selector(Coordinator.callHandler)

        searchField.sendsWholeSearchString = true

        return searchField
    }

    /* ****************************************
     *
     * ****************************************/
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = text.wrappedValue
        nsView.controlSize = .large

        context.coordinator.parent = self
    }

    /* ****************************************
     *
     * ****************************************/
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    /* ****************************************
     *
     * ****************************************/
    class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: SearchView

        /* ****************************************
         *
         * ****************************************/
        init(parent: SearchView) {
            self.parent = parent
        }

        /* ****************************************
         *
         * ****************************************/
        @objc func callHandler() {
            parent.action?()
        }

        /* ****************************************
         *
         * ****************************************/
        func controlTextDidChange(_ obj: Notification) {
            guard let control = obj.object as? NSSearchField else { return }
            parent.text.wrappedValue = control.stringValue
        }
    }
}
