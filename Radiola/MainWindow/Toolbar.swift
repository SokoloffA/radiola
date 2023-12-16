//
//  Toolbar.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.12.2023.
//

import SwiftUI

// MARK: - ToolbarPlayItem

struct ToolbarPlayItem: ToolbarContent {
    @StateObject var player: Player = Player.shared
    @State var windowGeometry: GeometryProxy

    /* ****************************************
     *
     * ****************************************/
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button(action: clicked) {
                Image(systemName: icon())
                    .resizable()
                    .frame(width: 22, height: 22)
            }
            .padding(.leading, 4)

            // --------------------------
            .overlay(alignment: .leading) {
                GeometryReader { tg in
                    VStack {
                        Text(player.songTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.headline)
                            .padding(EdgeInsets(top: -3, leading: 0, bottom: 1, trailing: 0))
                            .truncationMode(.tail)
                            .lineLimit(1)
                            .frame(minHeight: 16)

                        Text(player.station?.title ?? "")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .truncationMode(.tail)
                            .lineLimit(1)
                    }
                    .offset(x: 48)
                    .frame(width: windowGeometry.size.width - tg.frame(in: .global).origin.x - 100, alignment: .leading)
                }
            } // overlay
        }
    } // body

    /* ****************************************
     *
     * ****************************************/
    private func icon() -> String {
        switch player.status {
            case Player.Status.paused: return "play.fill"
            case Player.Status.connecting: return "pause.fill"
            case Player.Status.playing: return "pause.fill"
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func clicked() {
        player.toggle()
    }
}

// MARK: - ToolbarVolumeItem

struct ToolbarVolumeItem: ToolbarContent {
    @State private var volumeLevel: Float = 0.5

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            HStack {
                Button { print("X") } label: { Image(systemName: "speaker.slash.fill") }.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                Button { print("-") } label: { Image(systemName: "speaker.fill") }
                Slider(value: $volumeLevel).frame(width: 96).offset(y: 0)
                Button { print("+") } label: { Image(systemName: "speaker.wave.3.fill") }
            }
            .buttonStyle(.borderless)
        }
    } // body

    /* ****************************************
     *
     * ****************************************/
}
