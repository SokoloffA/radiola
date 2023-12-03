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

            if let n = appState.localStations.firstIndex(where: { $0.id == selectedProviderId }) {
                Text("Local \(appState.localStations[n].title)")
            } else if let n = appState.internetStations.firstIndex(where: { $0.id == selectedProviderId }) {
                InternetStationsView(provider: $appState.internetStations[n])
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
