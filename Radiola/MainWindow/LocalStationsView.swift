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
                        LocalStationRow(station: station)
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
    @ObservedObject var station: LocalStation

    var body: some View {
        VStack {
            HStack {
                Text(station.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.headline)

                ImageButton(iconOff: "star", iconOn: "star.fill", isSet: $station.isFavorite)
            }
            .padding(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 8))

            HStack {
                Text(station.url)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())

        .padding(EdgeInsets(top: 0, leading: 2, bottom: 1, trailing: 8))
    } // body

    private func setFavorite(_ value: Bool) {
    }
}
