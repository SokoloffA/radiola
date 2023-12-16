//
//  MainWindow.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 30.11.2023.
//

import SwiftUI

// MARK: - MainWindow

fileprivate class WindowController: NSWindowController, NSWindowDelegate {
    /* ****************************************
     *
     * ****************************************/
    func windowWillClose(_ notification: Notification) {
        print("CLOSE")
        MainWindow.instance = nil
        NSApp.setActivationPolicy(.accessory)
        // StationsWindow.instance = nil
    }
}

struct MainWindow: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedProviderId: UUID?
    fileprivate static var instance: NSWindowController?

    /* ****************************************
     *
     * ****************************************/
    static func show() {
        if instance == nil {
            print("CREATE")
            let rootView = MainWindow()
                .environmentObject(AppState.shared)

            let hostingController = NSHostingController(rootView: rootView)
            let window = NSWindow(contentViewController: hostingController)
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            window.toolbarStyle = .unified
            window.title = ""

            let controller = WindowController(window: window)
            instance = controller
            window.delegate = controller
            instance?.windowFrameAutosaveName = "StationsWindow"
        }

        instance?.showWindow(nil)
        instance?.window?.orderFrontRegardless()
        instance?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    static func isActie() -> Bool {
        return instance != nil
    }

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        NavigationView {
            SidebarView(selectedProviderId: $selectedProviderId)

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    if let list = appState.localStations.first(where: { $0.id == selectedProviderId }) {
                        LocalStationsView(list: list)
                    } else if let provider = appState.internetStations.first(where: { $0.id == selectedProviderId }) {
                        InternetStationsView(provider: provider)
                    }
                }
                .navigationTitle("")
                .toolbar {
                    ToolbarPlayItem(windowGeometry: geometry)
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
