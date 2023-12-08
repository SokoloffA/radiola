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
//    var text:    Binding<String>
    @Binding var text: String { didSet {
        print("DID SET")
    }}
    var action: (() -> Void)?
    var title: String

    /* ****************************************
     *
     * ****************************************/
    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField(frame: .zero)
        searchField.placeholderString = placeholder

        searchField.delegate = context.coordinator

        //   searchField.target = context.coordinator
        //   searchField.action = #selector(Coordinator.callHandler)

        // searchField.sendsWholeSearchString = true

        return searchField
    }

    /* ****************************************
     *
     * ****************************************/
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = _text.wrappedValue
        //   nsView.controlSize = .large

        print(context.transaction)
        print("UPDATE: '\(title)' '\(text)'")
//        context.coordinator.text = text.wrappedValue
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
        // @Binding var text: String
        var parent: SearchView

        init(parent: SearchView) {
            self.parent = parent
        }

        @objc func callHandler() {
            parent.action?()
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let control = obj.object as? NSSearchField else { return }
            print("controlTextDidChange: '\(parent.title)'")
            parent._text.update()
            parent._text.wrappedValue = control.stringValue
        }
    }
}
