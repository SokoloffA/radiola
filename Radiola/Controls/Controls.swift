//
//  Controls.swift
//  Radiola
//
//  Created by Alex Sokolov on 10.12.2023.
//

import SwiftUI

// MARK: - ImageButton

struct ImageButton: View {
    var iconOff: String
    var iconOn: String
    @Binding var isSet: Bool

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        Button {
            isSet.toggle()
        } label: {
            Image(systemName: isSet ? iconOn : iconOff)
                .resizable()
                .frame(width: 16, height: 16)
                .fixedSize()
                .foregroundStyle(isSet ? .yellow : .gray)
        }
        .buttonStyle(.borderless)
    } // body
}

// MARK: - VolumeView

struct VolumeView: View {
    var showMuteButton = true
    @StateObject private var player = Player.shared
    @State private var sliderHovered = false

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        HStack {
            if showMuteButton {
                Toggle(isOn: $player.isMuted) {
                    Image(systemName: "speaker.slash.fill")
                        .offset(y: 1)
                }
                .toggleStyle(.button)
            }

            Button(action: { player.decVolume() },
                   label: { Image(systemName: "speaker.fill") })
                .buttonStyle(.borderless)
                .disabled(player.isMuted || player.volume <= 0)

            Slider(value: $player.volume)
                .onHover { sliderHovered = $0 }
                .disabled(player.isMuted)
                .controlSize(.small)

            Button(action: { player.incVolume() },
                   label: { Image(systemName: "speaker.wave.3.fill") }
            )
            .buttonStyle(.borderless)
            .disabled(player.isMuted || player.volume >= 1)
        }
        .buttonStyle(.plain)
        .controlSize(.regular)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel], handler: mouseWheelEvent)
        }
    } // body

    /* ****************************************
     *
     * ****************************************/
    private func mouseWheelEvent(_ event: NSEvent) -> NSEvent {
        if sliderHovered {
            player.volume += Player.mouseWheelToVolume(delta: event.deltaY)
        }

        return event
    }
}
