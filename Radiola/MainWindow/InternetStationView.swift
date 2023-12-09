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
            InternetStationsSearchView(provider: provider, action: fetch)
            Divider()

            List(selection: $selectedStationId) {
                ForEach(provider.stations) { station in
                    InternetStationRow(station: station)
                }
            }
            .listStyle(.plain)
            .overlay { LoadingIndicator(provider.isLoading) }

            Text("")
                .frame(height: 36)
        }
    } // body

    /* ****************************************
     *
     * ****************************************/
    private func fetch() {
        Task {
            await provider.fetch()
        }
    }
}

// MARK: - InternetStationsSearchView

struct InternetStationsSearchView: View {
    @ObservedObject var provider: InternetStationProvider
    var action: () -> Void

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        HStack {
//            Text("Search on radio-browser.info by tags that")
//                .foregroundStyle(.secondary)
//                .lineLimit(1)

            Spacer()

            Menu(exactMatchToString(provider.isExactMatch)) {
                Button(exactMatchToString(true)) { provider.isExactMatch = true }
                Button(exactMatchToString(false)) { provider.isExactMatch = false }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            SearchView(placeholder: "Search", text: $provider.searchText, action: action)
                .frame(width: 400)
                .fixedSize()
                .padding(.trailing, 20)

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
