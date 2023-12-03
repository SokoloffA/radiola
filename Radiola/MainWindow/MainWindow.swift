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

            if let provider = appState.localStations.first(where: { $0.id == selectedProviderId }) {
                Text("Local \(provider.title)")
            } else if let provider = appState.internetStations.first(where: { $0.id == selectedProviderId }) {
                InternetStationsView(provider: provider)
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
