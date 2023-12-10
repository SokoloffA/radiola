//
//  Controls.swift
//  Radiola
//
//  Created by Alex Sokolov on 10.12.2023.
//

import SwiftUI

// MARK: - ImageButton

struct ImageButton: View {
    var iconOff: String
    var iconOn: String
    @Binding var isSet: Bool

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        Button {
            isSet.toggle()
        } label: {
            Image(systemName: isSet ? iconOn : iconOff)
                .resizable()
                .frame(width: 16, height: 16)
                .fixedSize()
                .foregroundStyle(isSet ? .yellow : .gray)
        }
        .buttonStyle(.borderless)
    } // body
}
