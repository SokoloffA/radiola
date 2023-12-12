//
//  LocalStationsView.swift
//  Radiola
//
//  Created by Alex Sokolov on 10.12.2023.
//

import SwiftUI

// MARK: - LocalStationsView

struct LocalStationsView: View {
    @ObservedObject var list: LocalStationList
    @State private var selectedItemId: UUID?
    @EnvironmentObject var appState: AppState

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        List(selection: $selectedItemId) {
            ForEach(list.items) { item in
                switch item {
                    case let .station(station: station):
                        LocalStationRow(list: list, station: station)
                    case let .group(group: group):
                        Text("GROUP")
                }
            }
        }
        .listStyle(.plain)
    } // body
}

// MARK: - LocalStationRow

struct LocalStationRow: View {
    @ObservedObject var list: LocalStationList
    @ObservedObject var station: LocalStation
    @FocusState private var isFocused: Bool

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        VStack {
            HStack {
                TextField("Station title", text: $station.title)
                    .font(.headline)

                ImageButton(iconOff: "star", iconOn: "star.fill", isSet: $station.isFavorite)
            }
            .padding(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 8))

            HStack {
                TextField("Station URL", text: $station.url)
                    .font(.caption)
            }
        }
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 0, leading: 2, bottom: 1, trailing: 8))
        .focused($isFocused)
        .onChange(of: isFocused, perform: onTextFocusChanged)
        .onChange(of: station.isFavorite, perform: { _ in boolValueChanged() })
    } // body

    /* ****************************************
     *
     * ****************************************/
    private func onTextFocusChanged(focused: Bool) {
        if !focused { list.save() }
    }

    /* ****************************************
     *
     * ****************************************/
    private func boolValueChanged() {
        list.save()
    }
}
