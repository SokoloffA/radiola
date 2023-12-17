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
        VStack {
            List(list.items, children: \.items, selection: $selectedItemId) { item in

                switch item {
                    case let .station(station: station):
                        StationRow(list: list, station: station)

                    case let .group(group: group):
                        GroupRow(list: list, group: group)
                }
            }
            .modifier(PlayOnDoubleClick(handler: doubleClicked))
        }
        .listStyle(.plain)
    } // body

    /* ****************************************
     *
     * ****************************************/
    private func doubleClicked() {
        guard
            let selectedItemId = selectedItemId,
            let station = list.first(byID: selectedItemId)
        else { return }

        Player.shared.switchStation(station: station)
    }
}

// MARK: - StationRow

fileprivate struct StationRow: View {
    @ObservedObject var list: LocalStationList
    @ObservedObject var station: LocalStation
    @FocusState private var isFocused: Bool
    @ObservedObject private var player = Player.shared

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
            .padding(EdgeInsets(top: 2, leading: 0, bottom: 0, trailing: 8))

            HStack {
                TextField("Station URL", text: $station.url)
                    .font(.caption)
            }
        }
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 1, trailing: 8))
        .focused($isFocused)
        .onChange(of: isFocused, perform: onTextFocusChanged)
        .onChange(of: station.isFavorite, perform: { _ in boolValueChanged() })

        .overlay(alignment: .leading) {
            if player.station?.id == station.id {
                Image(systemName: "circle.inset.filled")
                    .foregroundColor(.accentColor)
                    .opacity(0.8)
                    .offset(x: -18, y: 0)
            }
        }
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

// MARK: - GroupRow

fileprivate struct GroupRow: View {
    @ObservedObject var list: LocalStationList
    @ObservedObject var group: LocalStationGroup
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            TextField("Group title", text: $group.title)
                .font(.headline)
        }
        .padding(EdgeInsets(top: 7, leading: 2, bottom: 7, trailing: 2))
        .focused($isFocused)
        .onChange(of: isFocused, perform: onTextFocusChanged)
    }

    /* ****************************************
     *
     * ****************************************/
    private func onTextFocusChanged(focused: Bool) {
        if !focused { list.save() }
    }
}
