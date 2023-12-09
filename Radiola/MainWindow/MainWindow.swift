//
//  MainWindow.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 30.11.2023.
//

import SwiftUI

struct MainWindow: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedProviderId: UUID?

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        NavigationView {
            SidebarView(selectedProviderId: $selectedProviderId)

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    if let provider = appState.localStations.first(where: { $0.id == selectedProviderId }) {
                        Text("Local \(provider.title)")
                    } else if let provider = appState.internetStations.first(where: { $0.id == selectedProviderId }) {
                        InternetStationsView(provider: provider)
                    }
                }
                .navigationTitle("")
                .toolbar {
                    ToolbarPlayItem(station: LocalStation(title: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]", url: "http://www.rcgoldserver.eu:8253"), windowGeometry: geometry)
                    ToolbarVolumeItem()
                } // toolbar
            }
        }

        .frame(
            minWidth: 700,
            idealWidth: 1000,
            maxWidth: .infinity,
            minHeight: 400,
            idealHeight: 800,
            maxHeight: .infinity
        )

        .onAppear {
            selectedProviderId = appState.localStations[0].id
        }
    } // body
}
