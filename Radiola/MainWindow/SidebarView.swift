//
//  SidebarView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 30.11.2023.
//

import SwiftUI

struct SidebarView: View {
    static let minWidth: CGFloat = 200

    @Binding var selectedListId: UUID?
    @EnvironmentObject var appState: AppState

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        List(selection: $selectedListId) {
            Section("My lists") {
                ForEach(appState.localStations, id: \.self.id) { list in
                    Label(list.title, systemImage: list.icon).help(list.help ?? "")
                }
            }

            Section("Radio browser") {
                ForEach(appState.internetStations, id: \.self.id) { list in
                    Label(list.title, systemImage: list.icon).help(list.help ?? "")
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: SidebarView.minWidth)
        .toolbar { SidearToolbar() }
    } // body
}

// MARK: - Toolbar

struct SidearToolbar: ToolbarContent {
    /* ****************************************
     *
     * ****************************************/
    var body: some ToolbarContent {
        ToolbarItem(
            id: "toggleSidebar",
            placement: .automatic,
            showsByDefault: true
        ) {
            Button {
                toggleSidebar()
            } label: {
                Label("Toggle Sidebar", systemImage: "sidebar.left").offset(y: 1)
            }
            .help("Toggle Sidebar")
        }
    } // body

    /* ****************************************
     *
     * ****************************************/
    func toggleSidebar() {
        NSApp.keyWindow?
            .contentViewController?
            .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}
