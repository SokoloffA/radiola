//
//  InternetStationView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 30.11.2023.
//

import Foundation
import SwiftUI

struct InternetStationsView: View {
    @Binding var provider: InternetStationProvider
    @State var selectedStationId: UUID?
   // @State var stations: [InternetStation] = []

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        VStack(spacing: 0) {
            InternetStationsSearchView(provider: $provider)
            Divider()

            List(selection: $selectedStationId) {
                ForEach(provider.stations) { station in
                    InternetStationRow(station: station)
                }
            }
            .listStyle(.plain)
//            .task {
//                print("TASK \(Date())")
//                stations = await provider.fetch()
//            }
        }
    } // body
}

//MARK: - InternetStationsSearchView

struct InternetStationsSearchView: View {
    @Binding var provider: InternetStationProvider

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

            SearchView("Search", text: $provider.searchText)
                .frame(width: 400)
                .fixedSize()
                .padding(.trailing, 20)

            Menu(orderToString(provider.order)) {
                Button(orderToString(.byVotes)) { provider.order = .byVotes; fetch() }
                Button(orderToString(.byName)) { provider.order = .byName; fetch() }
                Button(orderToString(.byCountry)) { provider.order = .byCountry; fetch() }
                Button(orderToString(.byBitrate)) { provider.order = .byBitrate; fetch() }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        //        .background( Color(NSColor.controlBackgroundColor).opacity(0.5))
//        .onAppear() {
//            print("onAppear: \(Date()): ", provider.id)
//        }

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
    
    /* ****************************************
     *
     * ****************************************/
    @MainActor
    private func fetch() {
        
        Task {
            print("FETCH START 0")
            await provider.fetch()
            print("FETCH END 0")
        }
    }
}
