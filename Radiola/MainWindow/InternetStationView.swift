//
//  InternetStationView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 30.11.2023.
//

import Foundation
import SwiftUI

struct InternetStationsView: View {
    @ObservedObject var provider: InternetStationProvider
    @State private var selectedStationId: UUID?
    @EnvironmentObject var appState: AppState

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        VStack(spacing: 0) {
            Text("CURRENT: \(provider.title): \(provider.id)")
            TextField("\(provider.title)", text: $provider.searchText)
            Text("\(appState.internetStations[0].title): \(appState.internetStations[0].searchText)")
            Text("\(appState.internetStations[1].title): \(appState.internetStations[1].searchText)")
            Text("\(appState.internetStations[2].title): \(appState.internetStations[2].searchText)")
            SearchView(placeholder: "Search", text: $provider.searchText, action: nil, title: provider.title)
            Divider()
            // InternetStationsSearchView(provider: provider, action: fetch)
            Divider()
            /*
             List(selection: $selectedStationId) {
                 ForEach(provider.stations) { station in
                     InternetStationRow(station: station)
                 }
             }
             .listStyle(.plain)
             .overlay { LoadingIndicator(provider.isLoading) }*/
        }
    } // body

    /* ****************************************
     *
     * ****************************************/
    private func fetch() {
        Task {
            // await provider.fetch()
        }
    }
}

// MARK: - InternetStationsSearchView

struct InternetStationsSearchView: View {
    @ObservedObject var provider: InternetStationProvider
    var action: () -> Void
    @State var text: String = "qwerty"
    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        HStack {
            Spacer()

            Menu(exactMatchToString(provider.isExactMatch)) {
                Button(exactMatchToString(true)) { provider.isExactMatch = true }
                Button(exactMatchToString(false)) { provider.isExactMatch = false }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            TextField(provider.title, text: $provider.searchText)
//            SearchView(placeholder: "Search", text: $provider.searchText, action: action)
//                .frame(width: 400)
//                .fixedSize()
//                .padding(.trailing, 20)

            Menu(orderToString(provider.order)) {
                Button(orderToString(.byVotes)) { provider.order = .byVotes; action() }
                Button(orderToString(.byName)) { provider.order = .byName; action() }
                Button(orderToString(.byCountry)) { provider.order = .byCountry; action() }
                Button(orderToString(.byBitrate)) { provider.order = .byBitrate; action() }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    } // body

    /* ****************************************
     *
     * ****************************************/
    private func exactMatchToString(_ value: Bool) -> String {
        return value ? "matches with" : "contains"
    }

    /* ****************************************
     *
     * ****************************************/
    private func orderToString(_ order: InternetStationProvider.Order) -> String {
        switch order {
            case .byName: return "sort by name"
            case .byVotes: return "sort by votes"
            case .byCountry: return "sort by country"
            case .byBitrate: return "sort by bitrate"
        }
    }
}

// MARK: - LoadingIndicator

struct LoadingIndicator: View {
    var isLoading: Bool

    /* ****************************************
     *
     * ****************************************/
    init(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        if isLoading {
            ProgressView("Loading…")
                .scaleEffect(0.85)
                .progressViewStyle(.circular)
        }
    } // body
}
