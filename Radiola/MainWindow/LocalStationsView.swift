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

                Group {
                    switch item {
                        case let .station(station: station):
                            StationRow(list: list, station: station)

                        case let .group(group: group):
                            GroupRow(list: list, group: group)
                    }
                }
            }
        }
        .listStyle(.inset)
        .modifier(PlayOnDoubleClick(handler: doubleClicked))
    } // body

    /* ****************************************
     *
     * ****************************************/
    private func doubleClicked() {
        if let station = appState.station(byID: selectedItemId) {
            Player.shared.switchStation(station: station)
        }
    }
}

// MARK: - StationRow

fileprivate struct StationRow: View {
    @ObservedObject var list: LocalStationList
    @ObservedObject var station: LocalStation

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        VStack {
            HStack {
                Text(station.title)
                    .font(.headline)

                Spacer()

                ImageButton(iconOff: "star", iconOn: "star.fill", isSet: $station.isFavorite)
            }
            .padding(EdgeInsets(top: 2, leading: 0, bottom: 0, trailing: 8))

            HStack {
                Text(station.url)
                    .font(.caption)

                Spacer()
            }
            .padding(.bottom, 4)
        }
    } // body
}

// MARK: - GroupRow

fileprivate struct GroupRow: View {
    @ObservedObject var list: LocalStationList
    @ObservedObject var group: LocalStationGroup

    var body: some View {
        HStack {
            Text(group.title)
                .font(.headline)

            Spacer()
        }
        .padding(EdgeInsets(top: 7, leading: 2, bottom: 7, trailing: 2))
    }
}
