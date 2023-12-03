//
//  RowViews.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.12.2023.
//

import SwiftUI

struct InternetStationRow: View {
    var station: InternetStation

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        VStack {
            HStack {
                Text(station.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.headline)

                ImageButton(iconOff: "music.house", iconOn: "music.house.fill", isSet: .constant(true))
            }
            .padding(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 8))

            HStack {
                Text(station.url)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("32 k")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }.padding(EdgeInsets(top: 0, leading: 2, bottom: 1, trailing: 8))
        }
    } // body
}

// MARK: - Controls

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
            Label("", systemImage: isSet ? iconOn : iconOff)
                .labelStyle(.iconOnly)
                .foregroundStyle(isSet ? .yellow : .gray)
        }
        .buttonStyle(.borderless)
    } // body
}
