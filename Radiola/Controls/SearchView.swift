//
//  SearchView.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.12.2023.
//

import SwiftUI

// MARK: - SearchView

struct SearchView: NSViewRepresentable {
    private var placeholder: String
    @Binding var text: String

    /* ****************************************
     *
     * ****************************************/
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        _text = text
    }

    class Coordinator: NSObject, NSSearchFieldDelegate {
        @Binding var text: String

        /* ****************************************
         *
         * ****************************************/
        init(text: Binding<String>) {
            _text = text
        }

        /* ****************************************
         *
         * ****************************************/
        func controlTextDidChange(_ obj: Notification) {
            guard let searchField = obj.object as? CustomSearchField else { return }
            text = searchField.stringValue
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func makeCoordinator() -> SearchView.Coordinator {
        return Coordinator(text: $text)
    }

    /* ****************************************
     *
     * ****************************************/
    func makeNSView(context: Context) -> CustomSearchField {
        let searchField = CustomSearchField(frame: .zero)

        // delegate
        searchField.delegate = context.coordinator
        // placeholder
        searchField.placeholderString = placeholder
        // layout
        searchField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return searchField
    }

    /* ****************************************
     *
     * ****************************************/
    func updateNSView(_ nsView: CustomSearchField, context: Context) {
        nsView.stringValue = text
    }

    /* ****************************************
     *
     * ****************************************/
    class CustomSearchField: NSSearchField {
        override var controlSize: NSControl.ControlSize {
            get { return .large }
            set {}
        }

        /* ****************************************
         *
         * ****************************************/
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)

            cell = CustomSearchFieldCell(textCell: "")
        }

        /* ****************************************
         *
         * ****************************************/
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    /* ****************************************
     *
     * ****************************************/

    class CustomSearchFieldCell: NSSearchFieldCell {
        override init(textCell string: String) {
            super.init(textCell: string)

            controlSize = .large
            isEditable = true
            isBordered = true
            drawsBackground = true
            isBezeled = true
            isSelectable = true
            isScrollable = true
        }

        /* ****************************************
         *
         * ****************************************/
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
