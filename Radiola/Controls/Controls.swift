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

// MARK: - AlarmPopover

class AlarmPopover {
    var messageText: String = ""
    var informativeText: String?

    /* ****************************************
     *
     * ****************************************/
    func show(relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge = NSRectEdge.minY) {
        let popover = NSPopover()
        let controller = NSHostingController(rootView: RootView(parent: self, popover: popover))
        popover.contentViewController = controller
        popover.contentSize = controller.preferredContentSize
        popover.contentSize = NSSize(width: 500, height: 500)
        popover.behavior = .transient
        popover.animates = true

        popover.show(relativeTo: positioningRect, of: positioningView, preferredEdge: preferredEdge)
    }

    /* ****************************************
     *
     * ****************************************/
    func show(of positioningView: NSView, preferredEdge: NSRectEdge = NSRectEdge.minY) {
        show(relativeTo: positioningView.bounds, of: positioningView, preferredEdge: preferredEdge)
    }

    /* ****************************************
     *
     * ****************************************/
    struct RootView: View {
        var parent: AlarmPopover
        var popover: NSPopover

        /* ****************************************
         *
         * ****************************************/
        var body: some View {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .foregroundColor(.yellow)
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 20)

                VStack {
                    Text(parent.messageText)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let informativeText = parent.informativeText {
                        Text(informativeText)
                            .padding(.top, 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        Spacer()
                        Button("OK") {
                            popover.performClose(nil)
                        }
                    }
                }
            }.padding()
        } // body
    } // RootView
}

struct PlayOnDoubleClick: ViewModifier {
    var handler: () -> Void
    @State private var eventMonitor: Any?

    /* ****************************************
     *
     * ****************************************/
    func body(content: Content) -> some View {
        content
            .onAppear {
                eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { event in
                    if event.clickCount == 2 { handler() }
                    return event
                }
            }
            .onDisappear {
                NSEvent.removeMonitor(eventMonitor)
            }
    } // body
}
